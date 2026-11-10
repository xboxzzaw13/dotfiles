{ lib, pkgs, ... }:
{
  # Rootless CLI workflow; no root Docker daemon or docker group.
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    dockerSocket.enable = false;
  };
  environment.systemPackages = [ pkgs.podman-compose ];
  # The upstream module starts both API sockets by default. Mask the root API;
  # the user API remains available for an explicit systemctl --user start.
  systemd.services.podman.enable = false;
  systemd.sockets.podman.enable = false;
  systemd.user.sockets.podman.wantedBy = lib.mkForce [ ];
  # NixOS allocates subordinate IDs for normal users; verify with podman info.
}
