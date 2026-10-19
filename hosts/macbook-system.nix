{ ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = "afredojala";
  users.users.afredojala.home = "/Users/afredojala";

  # Keep the existing Nix install managed by its installer.
  nix.enable = false;

  # OmniWM listens to F18 directly, avoiding its Caps Lock tap-to-toggle behavior.
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [{
      HIDKeyboardModifierMappingSrc = 30064771129; # Caps Lock (0x700000039)
      HIDKeyboardModifierMappingDst = 30064771181; # F18 (0x70000006d)
    }];
  };

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
      "raycast"
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
