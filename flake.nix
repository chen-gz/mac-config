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
      hostname = "guangzong-mac-mini";
      system = "aarch64-darwin";
    in
    {
      # Export shared modules
      nixosModules = {
        home = import ./modules/home.nix;
        common = import ./modules/common.nix;
      };

      # 配置格式化工具
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

      darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # --- 1. 系统级别配置 ---
          (
            { pkgs, ... }:
            {
              nixpkgs.config.allowUnfree = true;

              # 将核心 CLI 工具放入系统包中，确保 PATH 始终能找到它们
              imports = [ ./modules/common.nix ];

              nix.settings = {
                experimental-features = "nix-command flakes";
                # Optimize for nix-direnv
                keep-outputs = true;
                keep-derivations = true;
              };

              system.primaryUser = username;

              programs.bash.enable = true;
              programs.zsh.enable = true;
              programs.fish.enable = true;

              environment.shells = [ pkgs.fish ];

              system.activationScripts.preActivation = {
                enable = true;
                text = ''
                  if [ -f /etc/shells ] && [ ! -L /etc/shells ]; then
                    echo "Backing up /etc/shells to /etc/shells.before-nix-darwin"
                    sudo mv /etc/shells /etc/shells.before-nix-darwin
                  fi
                  if [ -f /etc/bashrc ] && [ ! -L /etc/bashrc ]; then
                    echo "Backing up /etc/bashrc to /etc/bashrc.before-nix-darwin"
                    sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
                  fi
                  if [ -f /etc/zshrc ] && [ ! -L /etc/zshrc ]; then
                    echo "Backing up /etc/zshrc to /etc/zshrc.before-nix-darwin"
                    sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
                  fi

                  # Force update user shell to nix-managed fish
                  if [ "$(dscl . -read /Users/${username} UserShell | awk '{print $2}')" != "/run/current-system/sw/bin/fish" ]; then
                    echo "Updating user shell to /run/current-system/sw/bin/fish"
                    sudo dscl . -create /Users/${username} UserShell /run/current-system/sw/bin/fish
                  fi
                '';
              };

              users.users."${username}" = {
                home = "/Users/${username}";
                shell = pkgs.fish;
              };
              # users.users."${username}".home = "/Users/${username}";

              system.defaults = {
                dock.autohide = true;
                finder.AppleShowAllExtensions = true;

                # iTerm2 配置重定向
                CustomUserPreferences = {
                  "com.googlecode.iterm2" = {
                    PrefsCustomFolder = "~/.config/nix-darwin/iterm2";
                    LoadPrefsFromCustomFolder = true;
                  };
                };
              };

              system.stateVersion = 5;

              fonts.packages = [
                pkgs.nerd-fonts.jetbrains-mono
              ];
            }
          )

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

          # --- 3. Homebrew 软件包管理 ---
          (
            { ... }:
            {
              homebrew = {
                enable = true;
                onActivation.cleanup = "none";
                onActivation.autoUpdate = true;
                onActivation.upgrade = true;

                brews = [ "mas" ]; # Mac App Store CLI
                casks = [
                  "google-chrome"
                  "raycast"
                  "discord"
                  "iina"
                  "iterm2"
                  "google-drive"
                ];
                masApps = {
                  "Telegram Lite" = 946399090;
                };
              };
            }
          )

          # --- 4. Home Manager 配置 ---
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users."${username}" = import ./modules/home.nix;
          }
        ];
      };
    };
}
