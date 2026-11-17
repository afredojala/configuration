{ ... }:
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
}
