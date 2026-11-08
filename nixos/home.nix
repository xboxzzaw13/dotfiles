{ config, pkgs, ... }:

{
  home.username = "xboxzzaw13";
  home.homeDirectory = "/home/xboxzzaw13";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    bat
    eza
    jq
    tree
    htop
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "xboxzzaw13";
    userEmail = "2939306772@qq.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      credential.helper = "store";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "eza -lh --git";
      ls = "eza";
      rg = "ripgrep";
    };
  };

  programs.starship.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less -R";
  };
}
