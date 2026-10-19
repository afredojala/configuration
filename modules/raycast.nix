{ lib, ... }:
{
  # Raycast itself is a Homebrew cask in hosts/macbook-system.nix. Raycast 2.x
  # keeps its hotkey and settings in an encrypted database, not in defaults.

  # Start Raycast at login; -g keeps it from taking focus.
  launchd.agents.raycast = {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/open" "-g" "-a" "Raycast" ];
      RunAtLoad = true;
    };
  };

  # Free Command+Space for Raycast. -dict-add keeps other symbolic hotkeys.
  home.activation.disableSpotlightHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
      '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key>
      <array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array>
      <key>type</key><string>standard</string></dict></dict>'
    run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
