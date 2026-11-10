{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 10000;
    escapeTime = 10;
  };
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };
  # Preserve the small Python baseline. Compilers/LSPs belong in project devShells.
  home.packages = [ pkgs.python3 ];
  home.sessionVariables = { EDITOR = "nvim"; VISUAL = "nvim"; };
}
