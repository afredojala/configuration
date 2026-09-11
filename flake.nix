# flake.nix
# Don't copy and paste this. Read
#
{
  description = "My Home Manager configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-communties/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... } :
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      homeConfigurations = {
        afredojala = home-manager.lib.homeManagerConfiguration {
          inherit nixpkgs;
          modules = [ ./home.nix];
      };
    };
  };
}
