{
  description = "Darwin configuration with Home Manager and Homebrew integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.brew-src.follows = "brew-src";

    brew-src = {
      url = "github:homebrew/brew";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      brew-src,
      ...
    }:
    let
      # Systems to support
      supportedSystems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # 配置格式化工具
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      darwinConfigurations = {
        "gg-mac" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs;
            username = "guangzong";
            lib = nixpkgs.lib.extend (l: _: {
              hm = home-manager.lib.hm;
            });
          };
          modules = [
            ./modules/darwin.nix
            ./guangzong.nix
          ];
        };

        "connie-mac" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs;
            username = "connie";
            lib = nixpkgs.lib.extend (l: _: {
              hm = home-manager.lib.hm;
            });
          };
          modules = [
            ./modules/darwin.nix
            ./connie.nix
          ];
        };
      };
    };
}
