{ ... }:
{
  imports = [ ../../home.nix ../../home/development.nix ../../home/hyprland.nix ];
  home.username = "xboxzzaw13";
  home.homeDirectory = "/home/xboxzzaw13";
  home.stateVersion = "26.05";
  wayland.windowManager.hyprland.extraLuaFiles."host" = ./hyprland.lua;
  # Set before the compositor starts; retain dGPU-connected external outputs.
  xdg.configFile."uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES=/dev/dri/amd-igpu:/dev/dri/nvidia-dgpu
  '';
}
