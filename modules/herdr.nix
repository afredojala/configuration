{ lib, pkgs, ... }:
{
  # A read-only symlink, so settings changed inside herdr do not persist; edit this file.
  xdg.configFile."herdr/config.toml".source = ../dotfiles/herdr/config.toml;

  # Free Ctrl+Space for herdr's prefix. Ctrl+Option+Space and the Globe key
  # still switch input sources. -dict-add keeps other symbolic hotkeys.
  home.activation.disableInputSourceHotkey = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
    (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
        '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key>
        <array><integer>32</integer><integer>49</integer><integer>262144</integer></array>
        <key>type</key><string>standard</string></dict></dict>'
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '');
}
