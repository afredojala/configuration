{ config, lib, pkgs, ... }:
let
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.25.0/zjstatus.wasm";
    hash = "sha256-KCzqshnlbhkIyfrDOQckH+bD4e99hfqrPl9DjO+HuP4=";
  };
in
{
  programs.zellij = {
    enable = true;
    # Preserve manual startup; shell integration would auto-start Zellij.
    enableBashIntegration = false;
    enableZshIntegration = false;
    enableFishIntegration = false;
    extraConfig = builtins.readFile ../dotfiles/zellij/config.kdl;
    settings = {
      default_shell = lib.getExe config.programs.zsh.package;
      scrollback_editor = lib.getExe config.programs.helix.package;
      copy_command = if pkgs.stdenv.hostPlatform.isDarwin
        then "/usr/bin/pbcopy"
        else "${pkgs.wl-clipboard}/bin/wl-copy";
    };
    layouts.default = builtins.replaceStrings
      [ "@zjstatus@" ] [ "${zjstatus}" ]
      (builtins.readFile ../dotfiles/zellij/layouts/default.kdl);
  };
}
