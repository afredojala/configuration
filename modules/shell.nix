{ config, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = { size = 10000; save = 10000; };
    shellAliases = {
      c = "clear";
      nf = "fastfetch";
      pf = "fastfetch";
      ff = "fastfetch";
      ls = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
      v = "hx";
      vim = "hx";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      gp = "git push";
      gpl = "git pull";
      gst = "git stash";
      gcheck = "git checkout";
    };
  };
  programs.starship = {
    enable = true;
    settings.add_newline = true;
    enableZshIntegration = true;
  };
  programs.fzf = { enable = true; enableZshIntegration = true; };
  programs.zoxide = { enable = true; enableZshIntegration = true; };
  # Per-project environments from .envrc; nix-direnv caches `use flake` shells.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };
}
