{ config, ... }:
{
  # Explicit opt-in; open modules require Turing or newer hardware.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = false;
  };
  # No global CUDA, PRIME topology, persistence daemon or GPU containers.
}
