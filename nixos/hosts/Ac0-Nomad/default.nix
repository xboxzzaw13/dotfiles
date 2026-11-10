{ lib, pkgs, ... }:
{
  imports = [
    ../../configuration.nix
    ../../modules/hyprland.nix
    ../../modules/laptop.nix
    ../../modules/nvidia.nix
    ../../modules/containers.nix
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix)
    ./hardware-configuration.nix;

  assertions = [{
    assertion = builtins.pathExists ./hardware-configuration.nix;
    message = "Ac0-Nomad: generate hosts/Ac0-Nomad/hardware-configuration.nix on the target machine; see DEPLOYMENT.md. No disk layout is guessed.";
  }];
  networking.hostName = "Ac0-Nomad";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
  time.hardwareClockInLocalTime = true;
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    timeout = 5;
    efi.canTouchEfiVariables = true;
  };
  # Pinned nixpkgs default LTS: 6.18.57, with the 16ACHG6 audio quirk.
  boot.kernelPackages = pkgs.linuxPackages;
  hardware.cpu.amd.updateMicrocode = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.nvidia = {
    prime = {
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
    powerManagement.finegrained = true;
  };
  # Stable aliases: AQ_DRM_DEVICES is colon-separated, PCI by-path names are not safe.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", KERNEL=="card[0-9]*", KERNELS=="0000:05:00.0", SYMLINK+="dri/amd-igpu"
    SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", KERNEL=="card[0-9]*", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia-dgpu"
  '';
  # RAM/swap/hibernate, CPPC and charge thresholds await target measurements.
  # No model= audio override: upstream matches 17aa:3847 / CLSA0100 itself.
  users.users.xboxzzaw13 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # Set via nixos-enter + passwd during installation; no public password/hash.
  };
  home-manager.users.xboxzzaw13 = import ./home.nix;
}
