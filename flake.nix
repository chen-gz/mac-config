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

              # 将核心 CLI 工具放入系统包中，确保 PATH 始终能找到它们
              environment.systemPackages = with pkgs; [
                neovim
                git
                curl
                bat
                ripgrep
                fzf
                lazygit
                delta
                just
              ];

              nix.settings.experimental-features = "nix-command flakes";

              system.primaryUser = username;

              programs.bash.enable = false;
              programs.zsh.enable = false;
              programs.fish.enable = true;

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

                # 修正警告：将 delta 配置移动到独立模块
                programs.git.enable = true;
                programs.delta = {
                  enable = true;
                  enableGitIntegration = true;
                  options = {
                    line-numbers = true;
                    side-by-side = true;
                    navigate = true;
                    theme = "TwoDark";
                  };
                };

                # --- Lazygit 配置 ---
                programs.lazygit = {
                  enable = true;
                  settings = {
                    gui = {
                      showIcons = true;
                      skipDiscardChangeWarning = true;
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

                programs.helix = {
                  enable = true;
                  settings = {
                    editor = {
                      true-color = true;
                      bufferline = "multiple";
                      cursorline = true;
                      color-modes = true;
                      whitespace.render = "all";
                      indent-guides.render = true;
                      file-picker.hidden = false;
                    };
                    keys.normal = {
                      q = ":quit";
                    };
                  };
                };

                programs.fish = {
                  enable = true;

                  shellAliases = {
                    cat = "bat";
                    g = "git";
                    vi = "nvim";
                    lg = "lazygit";
                    cdd = "cd ~/Documents";
                    nixconf = "cd ~/.config/nix-darwin && nvim flake.nix";
                    nsw = "sudo -H nix run nix-darwin -- switch --flake ~/.config/nix-darwin#guangzong-mac-mini";
                  };

                  interactiveShellInit = ''
                    set -g fish_greeting ""
                    fish_add_path ~/.local/bin
                    fish_add_path ~/.cargo/bin
                    # 确保 Nix 系统路径在 PATH 中 (防止 Unknown command 报错)
                    # if not contains /run/current-system/sw/bin $PATH
                    #     fish_add_path --prepend --global /run/current-system/sw/bin
                    # end

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
