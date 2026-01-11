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

              environment.systemPackages = with pkgs; [
                neovim
                git
                curl
              ];

              nix.settings.experimental-features = "nix-command flakes";

              system.primaryUser = username;

              programs.bash.enable = false;
              programs.zsh.enable = false;
              programs.fish.enable = true;

              users.users."${username}".home = "/Users/${username}";

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
                "homebrew/homebrew-cask" = inputs.homebrew-cask;
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

                brews = [ "mas" ];
                casks = [
                  "google-chrome"
                  "raycast"
                  "discord"
                  "iina"
                  "iterm2"
                ];
              };
            }
          )

          # --- 4. Home Manager 配置 ---
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users."${username}" =
              { pkgs, ... }:
              {
                home.stateVersion = "25.11";

                home.packages = with pkgs; [
                  ripgrep
                  delta # 安装 delta 差异查看器
                ];

                # Git 配置，集成 delta
                programs.git = {
                  enable = true;
                  delta = {
                    enable = true;
                    options = {
                      line-numbers = true;
                      side-by-side = true;
                      navigate = true;
                      theme = "TwoDark";
                    };
                  };
                };

                # --- Lazygit 配置 ---
                programs.lazygit = {
                  enable = true;
                  settings = {
                    gui = {
                      showIcons = true; # 开启图标（需配合 Nerd Font）
                      skipDiscardChangeWarning = true; # 跳过放弃更改的警告提示
                    };
                    git.paging = {
                      colorArg = "always";
                      pager = "delta --dark --paging=never";
                    };
                  };
                };

                programs.fzf = {
                  enable = true;
                  enableFishIntegration = true;
                };

                programs.bat = {
                  enable = true;
                  config = {
                    theme = "TwoDark";
                  };
                };

                programs.starship = {
                  enable = true;
                  settings = {
                    add_newline = false;
                    line_break.disabled = true;
                  };
                };

                programs.fish = {
                  enable = true;

                  shellAliases = {
                    cat = "bat";
                    g = "git";
                    vi = "nvim";
                    lg = "lazygit"; # 添加快捷命令
                    cdd = "cd ~/Documents";
                    nixconf = "cd ~/.config/nix-darwin && nvim flake.nix";
                  };

                  interactiveShellInit = ''
                    set -g fish_greeting ""
                    fish_add_path ~/.local/bin
                    fish_add_path ~/.cargo/bin

                    set -x GPG_TTY (tty)
                    if test (uname) = "Darwin"
                        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
                        gpg-connect-agent updatestartuptty /bye >/dev/null
                    end

                    set -gx PATH $PATH /Users/guangzong/.lmstudio/bin
                    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
                  '';
                };
              };
          }
        ];
      };
    };
}
