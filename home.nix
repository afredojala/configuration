{ lib, pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      hello
      cowsay
      lolcat
    ];

    username = "afredojala";
    homeDirectory = "/home/afredojala";

    stateVersion = "23.11";
  };
}
