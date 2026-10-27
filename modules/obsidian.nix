{ pkgs, ... }:
let
  vault = "~/Documents/Foffe";
in
{
  # Obsidian itself is a Homebrew cask in hosts/macbook-system.nix.

  # Raycast script command; its hotkey lives in Raycast's encrypted settings.
  home.file.".config/raycast/scripts/obsidian-daily-log.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      # @raycast.schemaVersion 1
      # @raycast.title Log to Daily Note
      # @raycast.mode silent
      # @raycast.packageName Obsidian
      # @raycast.icon 📝
      # @raycast.argument1 { "type": "text", "placeholder": "What happened?" }
      exec ${pkgs.python3}/bin/python3 ${../dotfiles/obsidian/daily-log.py} ${vault} "$1"
    '';
  };
}
