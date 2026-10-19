{ lib, pkgs, nixpkgs-unstable, ... }:
let
  omniwm = nixpkgs-unstable.legacyPackages.aarch64-darwin.omniwm.overrideAttrs (_: {
    # Keep the installed release until nixpkgs catches up from 0.7.4.
    version = "0.7.6";
    # Preserve the upstream code signature; Darwin fixups modify the bundle.
    dontFixup = true;
    src = nixpkgs-unstable.legacyPackages.aarch64-darwin.fetchurl {
      url = "https://github.com/OmniNull/OmniWM/releases/download/v0.7.6/OmniWM-v0.7.6.zip";
      hash = "sha256-7IxhRqbyGnnhxArHDWESF2K5PPU80wjmPrROis4g/Nw=";
    };
  });
in
{
  # Keep the config writable in OmniWM while applying our preferences.
  home.packages = [ omniwm ];

  launchd.agents.omniwm-bar-on-switch = {
    enable = false;
    config = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${../dotfiles/omniwm/bar-on-switch.py}"
        "${omniwm}/bin/omniwmctl"
        "1.0" # Seconds visible after the last focus/workspace change.
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardErrorPath = "/tmp/omniwm-bar-on-switch.log";
    };
  };

  home.activation.omniwmPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${../dotfiles/omniwm/apply-preferences.py} \
      ${../dotfiles/omniwm/preferences.toml}
  '';
}
