{ pkgs, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/helix.nix
    ./modules/git.nix
    ./modules/zellij.nix
    ./modules/terminal.nix
    ./modules/access.nix
    ./modules/cloud.nix
  ];

  home.packages = with pkgs; [
    age bat btop duf eza fastfetch fd glow jq just
    lazygit ncdu ripgrep sops tldr tree yazi rsync wget zip unzip
    # Global runtimes so project tests can run; uv also provides Python.
    nodejs uv
  ];

  programs.home-manager.enable = true;
}
