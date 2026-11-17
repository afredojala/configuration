{ pkgs, nixpkgs-unstable, ... }:
let
  unstable = nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./modules/shell.nix
    ./modules/helix.nix
    ./modules/git.nix
    ./modules/zellij.nix
    ./modules/pi.nix
    ./modules/terminal.nix
    ./modules/access.nix
    ./modules/cloud.nix
  ];

  home.packages = with pkgs; [
    age bat btop duf eza fastfetch fd glow jq just
    lazygit mkcert ncdu ripgrep sops tldr tree yazi rsync wget xz zip unzip
    # Global runtimes so project tests can run; uv also provides Python.
    # rustup rather than nixpkgs rustc so projects can pin toolchains via rust-toolchain.toml.
    nodejs uv rustup
    # 26.05 ships pi 0.75; unstable tracks the current 1.x releases.
    unstable.pi-coding-agent
  ];

  # Binaries from `cargo install`.
  home.sessionPath = [ "$HOME/.cargo/bin" "$HOME/.local/bin" ];
  # nodejs's default global prefix is the read-only store; `npm i -g` lands in ~/.local/bin.
  home.sessionVariables.NPM_CONFIG_PREFIX = "$HOME/.local";

  programs.home-manager.enable = true;
}
