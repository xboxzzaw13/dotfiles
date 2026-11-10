{ lib, pkgs, ... }:
{
  # Shared baseline; boot, hardware, users and stateVersion belong to hosts.
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # Replace NixOS's appended cache default to avoid duplicate official entries.
    substituters = lib.mkForce [
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=30"
      "https://cache.nixos.org?priority=40"
    ];
    trusted-public-keys = lib.mkForce [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    require-sigs = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  services.openssh.enable = lib.mkDefault false;
  security.sudo.wheelNeedsPassword = true;
  time.timeZone = lib.mkDefault "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  hardware.enableRedistributableFirmware = true;
  services.journald.settings.Journal = {
    SystemMaxUse = "500M";
    MaxRetentionSec = "1month";
  };
  # Recovery tools remain available even if Home Manager fails.
  environment.systemPackages = with pkgs; [ git vim curl wget pciutils usbutils ];
}
