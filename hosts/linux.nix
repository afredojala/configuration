{ lib, ... }:
{
  home.username = "afredojala";
  home.homeDirectory = "/home/afredojala";
  home.stateVersion = "23.11";

  # Preserve Nix initialization from the existing Linux shell configuration.
  programs.zsh.envExtra = ''
    if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
  '';
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -f "$HOME/.zshrc_custom" ]]; then
      source "$HOME/.zshrc_custom"
    fi
  '';
  programs.zsh.shellAliases = {
    shutdown = "systemctl poweroff";
    wifi = "nmtui";
  };
}
