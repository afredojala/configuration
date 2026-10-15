{ config, lib, pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    # Manage the app directly, without a systemd service or extra Bat syntax.
    systemd.enable = false;
    installBatSyntax = false;
    enableZshIntegration = true;
    settings = {
      command = "${lib.getExe config.programs.zsh.package} -l";
      keybind = [ "shift+enter=text:\\x1b\\r" ];
      mouse-scroll-multiplier = "precision:0.5,discrete:0.5";
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # Left Option drives Zellij's Alt bindings; right Option retains text input.
      macos-option-as-alt = "left";
      auto-update = "off";
    };
  };
}
