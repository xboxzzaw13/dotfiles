{ pkgs, ... }:
let
  screenshot = pkgs.writeShellApplication {
    name = "desktop-screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard libnotify coreutils ];
    text = builtins.readFile ../scripts/screenshot.sh;
  };
  clipboard = pkgs.writeShellApplication {
    name = "desktop-clipboard";
    runtimeInputs = with pkgs; [ cliphist rofi wl-clipboard coreutils ];
    text = builtins.readFile ../scripts/clipboard.sh;
  };
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # NixOS owns the compositor and portal packages; UWSM owns session lifecycle.
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";
    extraConfig = builtins.readFile ../config/wm/hypr/hyprland.lua;
  };
  programs.kitty = { enable = true; font.name = "Maple Mono Normal CN"; };
  programs.firefox.enable = true;
  home.packages = with pkgs; [
    rofi wl-clipboard cliphist pavucontrol playerctl brightnessctl libnotify
    wireplumber networkmanager blueman hypridle
    screenshot clipboard
  ];
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Native GTK Wayland uses text-input. Qt fallback remains per-application.
    MOZ_ENABLE_WAYLAND = "1";
  };
  services.mako.enable = true;
  services.polkit-gnome.enable = true;
  services.cliphist = {
    enable = true;
    # One MIME-auto watcher; no primary-selection history or duplicate image unit.
    allowImages = false;
  };
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];
      clock.format = "{:%m-%d %a %H:%M}";
      pulseaudio = { format = "VOL {volume}%"; format-muted = "MUTE"; on-click = "pavucontrol"; };
      network = { format-wifi = "{essid}"; format-ethernet = "LAN"; format-disconnected = "Offline"; on-click = "kitty -e nmtui"; };
      battery = { format = "BAT {capacity}%"; format-charging = "AC {capacity}%"; };
    };
  };
  programs.hyprlock = {
    enable = true;
    settings = {
      general.ignore_empty_input = true;
      background = [{ monitor = ""; color = "rgba(181818ff)"; }];
      input-field = [{ monitor = ""; size = "280, 56"; placeholder_text = "Password"; }];
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        # UWSM deliberately excludes XDG_SESSION_ID from the user manager.
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-sessions";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        # Wait for the Wayland session-lock protocol before releasing sleep inhibitor.
        inhibit_sleep = 3;
      };
      listener = [
        { timeout = 300; on-timeout = "${pkgs.systemd}/bin/loginctl lock-sessions"; }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
      ];
    };
  };
  # Fcitx runs once through XDG autostart, enabled by NixOS + UWSM.
  # The profile is declarative; learned dictionaries remain outside Nix's store.
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=pinyin

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=pinyin
    Layout=

    [GroupOrder]
    0=Default
  '';
}
