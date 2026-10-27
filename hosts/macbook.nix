{ ... }:
{
  imports = [ ../modules/omniwm.nix ../modules/sketchybar.nix ../modules/raycast.nix ../modules/obsidian.nix ];

  home.username = "afredojala";
  home.homeDirectory = "/Users/afredojala";
  home.stateVersion = "26.05";

  # OrbStack can't edit the Home Manager-managed zsh files, so add its CLIs (docker, orb)
  # here. Appended so Nix-managed tools like kubectl keep precedence.
  programs.zsh.envExtra = ''
    export PATH="$PATH:$HOME/.orbstack/bin"
  '';
}
