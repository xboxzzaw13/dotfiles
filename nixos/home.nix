{ pkgs, ... }:
{
  # Identity and first-install stateVersion are selected by each host.
  programs.home-manager.enable = true;
  xdg.enable = true;
  home.packages = with pkgs; [ ripgrep fd jq tree btop fastfetch ];
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "eza -lh --git";
      ls = "eza";
      # ripgrep's executable is rg; the old `rg = ripgrep` alias was broken.
    };
  };
  programs.starship.enable = true;
  programs.fzf = { enable = true; enableBashIntegration = true; };
  programs.zoxide = { enable = true; enableBashIntegration = true; };
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.yazi.enable = true;
  programs.neovim = { enable = true; defaultEditor = true; };
  programs.git = {
    enable = true;
    settings = {
      user.name = "xboxzzaw13";
      user.email = "2939306772@qq.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      credential.helper = "cache --timeout=3600";
    };
  };
  programs.delta = { enable = true; enableGitIntegration = true; };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = false;
      HashKnownHosts = true;
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
    };
  };
  services.ssh-agent.enable = true;
  home.sessionVariables.PAGER = "less -R";
}
