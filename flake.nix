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
      username = "guangzong";
      hostname = "mac-mini";
      system = "aarch64-darwin";
    in
    {
      # 配置格式化工具
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

      darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          # --- 1. 系统级别配置 ---
          ./modules/darwin/system.nix

          # --- 2. Nix-Homebrew 配置 ---
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "${username}";
              autoMigrate = true;
              taps = {
                "homebrew/homebrew-core" = inputs.homebrew-core;
              };
              mutableTaps = false;
            };
          }

          ./modules/darwin/apps.nix                  # --- 3. Homebrew 软件包管理--

          home-manager.darwinModules.home-manager    # --- 4. Home Manager 配置 ---
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users."${username}" = import ./modules/home/default.nix;
          }
        ];
      };

      # --- 5. Ubuntu / Linux (x86_64) 独立 Home Manager 配置 ---
      # 这一块专门用于在 Ubuntu (x86_64) 上通过 Home Manager 独立管理用户配置
      # 使用命令: home-manager switch --flake .#linux-server
      homeConfigurations."linux-server" =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs; # 这里的架构改为 x86_64-linux 以适配 Ubuntu
          modules = [
            ./modules/home/default.nix
            {
              home = {
                inherit username;
                homeDirectory = "/${if pkgs.stdenv.isDarwin then "Users" else "home"}/${username}"; # 自动根据系统确定路径
              };
            }
          ];
        };
    };
}
