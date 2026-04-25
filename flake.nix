{
  description = "Darwin configuration with Home Manager and Homebrew integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
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
      ...
    }:
    let
      # Systems to support
      supportedSystems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
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
            ./modules/darwin/common.nix
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
            ./modules/darwin/common.nix
            ./connie.nix
          ];
        };
      };

      # --- Linux Home Manager 配置 ---
      homeConfigurations."gg-linux" =
        let
          # Detect system architecture, default to x86_64-linux if cannot detect
          system = if builtins.hasAttr builtins.currentSystem nixpkgs.legacyPackages
                   then builtins.currentSystem
                   else "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib.extend (l: _: {
            hm = home-manager.lib.hm;
          });
          guangzongConfig = import ./guangzong.nix;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs pkgs lib;
          };
          modules = [
            (args: (guangzongConfig args).home-manager.users.guangzong)
            {
              home = {
                username = "guangzong";
                homeDirectory =
                  let
                    envHome = builtins.getEnv "HOME";
                  in
                  if envHome != "" then envHome else "/home/guangzong";
              };
            }
          ];
        };
    };
}
