{ pkgs, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/helix.nix
    ./modules/git.nix
    ./modules/zellij.nix
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
  ];

  # Binaries from `cargo install`.
  home.sessionPath = [ "$HOME/.cargo/bin" ];

  programs.home-manager.enable = true;
}
