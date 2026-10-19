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
      keybind = [ "shift+enter=text:\\x1b\\r" ]
        # Command stands in for Alt in Zellij's Alt shortcuts, since Option types text.
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin
          (map (key: "super+${key}=esc:${key}") [ "h" "j" "k" "l" "n" "i" "o" "f" "y" "g" "+" "-" ]);
      mouse-scroll-multiplier = "precision:0.5,discrete:0.5";
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # Both Option keys keep macOS text input (@, {, [, |, \ on Swedish layouts).
      macos-option-as-alt = false;
      auto-update = "off";
    };
  };
}
