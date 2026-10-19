{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;

  networking.hostName = "Ac0-Nomad";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
    serif     = [ "Noto Serif CJK SC" "Noto Serif" ];
    monospace = [ "Noto Sans Mono CJK SC" "DejaVu Sans Mono" ];
    emoji     = [ "Noto Color Emoji" ];
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [ fcitx5-chinese-addons fcitx5-gtk fcitx5-qt ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.nju.edu.cn/nix-channels/store"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  users.users.xboxzzaw13 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    initialPassword = "changeme";
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  services.libinput.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [ kitty neovim firefox fastfetch];

  system.stateVersion = "26.05";
}
