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
                fish
                git
                curl
                bat
                helix
                ripgrep
                fzf
                lazygit
                delta
                just
                devbox
                just-lsp
                gemini-cli
              ];

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
                    git.pagers = [
                      {
                        colorArg = "always";
                        pager = "delta --dark --paging=never";
                      }
                    ];
                  };
                };

                programs.direnv = {
                  enable = true;
                  nix-direnv.enable = true;
                  enableFishIntegration = true;
                  config = {
                    global = {
                      log_format = "";
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
                    theme = "catppuccin_frappe";
                    editor = {
                      true-color = true;
                      line-number = "relative";
                      bufferline = "multiple";
                      cursorline = true;
                      color-modes = true;
                      whitespace = {
                        render = "all";
                        characters = {
                          space = " ";
                          tab = "→";
                          newline = " ";
                        };
                      };
                      indent-guides.render = true;
                      file-picker.hidden = false;
                      cursor-shape = {
                        insert = "bar";
                        normal = "block";
                        select = "underline";
                      };
                      lsp.display-messages = true;
                    };
                    keys.normal = {
                      q = ":quit";
                    };
                  };
                  languages = {
                    language = [{
                      name = "just";
                      auto-format = true;
                      language-servers = [ "just-lsp" ];
                    }];
                    language-server = {
                      just-lsp = {
                        command = "just-lsp";
                      };
                    };
                  };
                };

                programs.tmux = {
                  enable = true;
                  mouse = true;
                  prefix = "C-a";
                  extraConfig = ''
                    bind -r k select-pane -U
                    bind -r j select-pane -D
                    bind -r h select-pane -L
                    bind -r l select-pane -R

                    bind C-a send-prefix
                    unbind C-b

                    # Smart pane switching with awareness of Helix splits
                    is_helix="ps -o state= -o comm= -t '#{pane_tty}' \
                        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?(hx|helix)$'"

                    bind-key -n 'C-h' if-shell "$is_helix" 'send-keys C-h'  'select-pane -L'
                    bind-key -n 'C-j' if-shell "$is_helix" 'send-keys C-j'  'select-pane -D'
                    bind-key -n 'C-k' if-shell "$is_helix" 'send-keys C-k'  'select-pane -U'
                    bind-key -n 'C-l' if-shell "$is_helix" 'send-keys C-l'  'select-pane -R'
                  '';
                };

                programs.fish = {
                  enable = true;

                  shellAliases = {
                    cat = "bat";
                    g = "git";
                    vi = "hx";
                    vim = "hx";
                    lg = "lazygit";
                    blog = "cd ~/Documents/chen-gz.github.io";
                    nixconf = "cd ~/.config/nix-darwin && hx flake.nix";
                    nsw = "sudo -H nix run nix-darwin -- switch --flake ~/.config/nix-darwin#guangzong-mac-mini";
                  };

                  interactiveShellInit = ''
                    set -g fish_greeting ""
                    set -gx DIRENV_LOG_FORMAT ""
                    fish_add_path ~/.local/bin
                    fish_add_path ~/.cargo/bin
                    # 确保 Nix 系统路径在 PATH 中 (防止 Unknown command 报错)
                    if not contains /run/current-system/sw/bin $PATH
                        fish_add_path --prepend --global /run/current-system/sw/bin
                    end

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
