{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start -e -D Hyprland hyprland.desktop'";
      user = "greeter";
    };
  };
  security.polkit.enable = true;
  # Home Manager installs the lock screen; NixOS supplies authentication.
  security.pam.services.hyprlock = { };
  services.libinput.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  fonts.packages = with pkgs; [
    maple-mono."Normal-CN" noto-fonts noto-fonts-cjk-sans
    noto-fonts-cjk-serif noto-fonts-color-emoji
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
    serif = [ "Noto Serif CJK SC" "Noto Serif" ];
    monospace = [ "Maple Mono Normal CN" ];
    emoji = [ "Noto Color Emoji" ];
  };
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = [ pkgs.qt6Packages.fcitx5-chinese-addons ];
    };
  };
}
