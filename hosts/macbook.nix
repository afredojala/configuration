{ lib, ... }:
{
  imports = [ ../modules/omniwm.nix ../modules/sketchybar.nix ../modules/raycast.nix ../modules/obsidian.nix ../modules/herdr-notify.nix ];

  home.username = "afredojala";
  home.homeDirectory = "/Users/afredojala";
  home.stateVersion = "26.05";

  # OrbStack can't edit the Home Manager-managed zsh files, so add its CLIs (docker, orb)
  # here. Appended so Nix-managed tools like kubectl keep precedence.
  programs.zsh.envExtra = ''
    export PATH="$PATH:$HOME/.orbstack/bin"
  '';

  # Each pytest-xdist worker starts its own testcontainers; the 12-worker default
  # saturates CPU and RAM on this machine.
  home.sessionVariables.TEST_WORKERS = "4";

  # The check runs `tccutil reset SystemPolicyAppBundles` when it fails, which wipes
  # every app's App Management grant. Copying Ghostty and OmniWM only needs the grant
  # when one of them changes.
  targets.darwin.copyApps.enableChecks = false;

  # Polar night, drawn from herdr's polar-aurora theme. macOS stores the
  # resolved store path, so compare against that to skip redundant resets.
  home.file.".local/share/wallpaper/polar-night.png".source = ../dotfiles/wallpaper/polar-night.png;
  home.activation.wallpaper = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    wallpaper=$(/usr/bin/readlink -f "$HOME/.local/share/wallpaper/polar-night.png")
    current=$(/usr/bin/osascript -e 'tell application "System Events" to get picture of desktop 1' 2>/dev/null || true)
    if [ "$current" != "$wallpaper" ]; then
      run /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$wallpaper\"" \
        || echo "Could not set the wallpaper; allow Automation for System Events." >&2
    fi
  '';
}
