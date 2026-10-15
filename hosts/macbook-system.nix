{ ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = "afredojala";
  users.users.afredojala.home = "/Users/afredojala";

  # Keep the existing Nix install managed by its installer.
  nix.enable = false;

  nix-homebrew = {
    enable = true;
    user = "afredojala";
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "slack"
      "claude"
      "chatgpt"
      "morgen"
      "shortwave"
      "claude-code"
      "codex"
      "beeper"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "uBlock Origin Lite" = 6745342698;
    };
    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
    };
  };
}
