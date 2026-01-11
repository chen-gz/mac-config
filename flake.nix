{
  description = "Darwin configuration with Lix, Home Manager and Homebrew integration";

  inputs = {
    # 核心 NixOS/Darwin 软件源
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Lix: 一个更现代、更高性能的 Nix 派生版本
    lix-module = {
      url = "https://git.lix.systems/lix-project/lix-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MacOS 系统管理
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # 用户级别配置管理
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nix-Homebrew: 让 Nix 声明式管理 Homebrew 本身
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # 声明式锁定 Homebrew Tap
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, lix-module, ... }:
  let
    username = "guangzong";
    hostname = "guangzong-mac-mini";
    system = "aarch64-darwin";
  in {
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # --- 0. 启用 Lix ---
        lix-module.nixosModules.default

        # --- 1. 系统级别配置 ---
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = with pkgs; [
            neovim
            git
            curl
          ];

          # 启用 Flakes 特性
          nix.settings.experimental-features = "nix-command flakes";

          # 设置用户的默认 Shell 为 Fish
          programs.fish.enable = true;
          users.users."${username}".home = "/Users/${username}";

          # MacOS 系统偏好设置
          system.defaults = {
            dock.autohide = true;
            finder.AppleShowAllExtensions = true;
            # NSGlobalDomain.AppleInterfaceStyle = "Dark";
          };

          system.stateVersion = 5;

          fonts.packages = [
            # 在 2026 年的 nixpkgs 中，nerdfonts 已拆分为独立包，避免下载全集
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
            # onActivation.cleanup = "zap"; # this will cleanup manually installation
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
            # 启用 bat
          programs.bat = {
            enable = true;
            config = {
              theme = "TwoDark"; # 设置主题
            };
          };

          # 启用 starship
          programs.starship = {
            enable = true;
            # 也可以在这里直接写自定义配置
            settings = {
              add_newline = false;
              line_break.disabled = true;
            };
          };

          # 既然你用 fish，记得开启 fish 的集成
          programs.fish = {
            enable = true;
            shellAliases = {
              cat = "bat"; # 把 cat 别名设为 bat，从此告别黑白代码
            };
          };

          home.stateVersion = "25.11";
            home.packages = with pkgs; [
              fzf
              ripgrep
              bat
              starship
            ];
            programs.fish.enable = true;
          };
        }
      ];
    };
  };
}
