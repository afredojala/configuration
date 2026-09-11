{ lib, pkgs, ... };
{
  home = {
    packages = with pkgs; [
      hello
    ];

    username = "afredojala";
    homeDirectory = "/home/afredojala";

    stateVersion = "23.11";
  }
}
