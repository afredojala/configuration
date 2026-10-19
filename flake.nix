{
  description = "Shared Linux and macOS Home Manager configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    # OmniWM is not packaged on 26.05; keep other packages on stable.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, nix-darwin, nix-homebrew, ... }:
    let
      mkHome = system: host: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        extraSpecialArgs = { inherit nixpkgs-unstable; };
        modules = [ ./home.nix host ];
      };
    in {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          ./hosts/macbook-system.nix
        ];
      };
      homeConfigurations = {
        afredojala = mkHome "x86_64-linux" ./hosts/linux.nix;
        macbook = mkHome "aarch64-darwin" ./hosts/macbook.nix;
      };
    };
}
