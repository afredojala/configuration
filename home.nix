{ lib, pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      hello
      cowsay
      lolcat
      age
      bat
      btop
      duf
      eza
      fastfetch
      fd
      glow
      jq
      just
      lazygit
      ncdu
      ripgrep
      sops
      tldr
      tree
      yazi
      zellij
      zoxide
    ];


    username = "afredojala";
    homeDirectory = "/home/afredojala";

    stateVersion = "23.11";
  };
  
  programs.home-manager.enable = true;
}
