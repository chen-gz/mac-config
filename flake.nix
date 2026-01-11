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

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, ... }:
  let
    username = "guangzong";
    hostname = "guangzong-mac-mini";
    system = "aarch64-darwin";
  in {
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # --- 1. 系统级别配置 ---
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = with pkgs; [
            neovim
            git
            curl
          ];

          nix.settings.experimental-features = "nix-command flakes";

          # 修复错误：设置主要用户
          system.primaryUser = username;

          # 系统级启用 fish
          programs.fish.enable = true;
          users.users."${username}".home = "/Users/${username}";

          system.defaults = {
            dock.autohide = true;
            finder.AppleShowAllExtensions = true;
          };

          system.stateVersion = 5;

          fonts.packages = [
            pkgs.nerd-fonts.jetbrains-mono
          ];
        })

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
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
            };
            mutableTaps = false;
          };
        }

        # --- 3. Homebrew 软件包管理 ---
        ({ ... }: {
          homebrew = {
            enable = true;
            onActivation.cleanup = "none";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;

            brews = [ "mas" ]; 
            casks = [
              "google-chrome"
              "raycast"
              "discord"
              "iina" 
            ];
          };
        })

        # --- 4. Home Manager 配置 ---
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."${username}" = { pkgs, ... }: {
            home.stateVersion = "25.11";
            
            home.packages = with pkgs; [
              fzf
              ripgrep
            ];

            programs.bat = {
              enable = true;
              config = { theme = "TwoDark"; };
            };

            programs.starship = {
              enable = true;
              settings = {
                add_newline = false;
                line_break.disabled = true;
              };
            };

            # 保持用户级的 fish 启用
            programs.fish = {
              enable = true;
              shellAliases = {
                cat = "bat";
              };
            };
          };
        }
      ];
    };
  };
}
