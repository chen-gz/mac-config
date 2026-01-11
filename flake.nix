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
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

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

              # 禁用系统级 Shell 管理，保留自定义的 /etc/bashrc 等
              programs.bash.enable = false;
              programs.zsh.enable = false;
              programs.fish.enable = true;

              users.users."${username}".home = "/Users/${username}";

              # 提示：这里的设置会导致执行 switch 时 Dock/Finder 重启（闪烁原因）
              system.defaults = {
                dock.autohide = true;
                finder.AppleShowAllExtensions = true;
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
                ];
              };
            }
          )

          # --- 4. Home Manager 配置 ---
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # 添加此行：如果文件冲突，自动备份旧文件（例如 .config.fish -> .config.fish.backup）
            home-manager.backupFileExtension = "backup";
            home-manager.users."${username}" =
              { pkgs, ... }:
              {
                home.stateVersion = "25.11";

                home.packages = with pkgs; [
                  ripgrep
                ];

                # 使用原生的 fzf 模块，加载速度更快
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
                    cdd = "cd ~/Documents";
                    nixconf = "cd ~/.config/nix-darwin && nvim flake.nix";
                  };

                  interactiveShellInit = ''
                    # 设置 Fish 欢迎语为空
                    set -g fish_greeting ""

                    # 额外的 PATH 设置
                    fish_add_path ~/.local/bin
                    fish_add_path ~/.cargo/bin
                    
                    # GPG and SSH agent setup
                    set -x GPG_TTY (tty)
                    if test (uname) = "Darwin"
                        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
                        gpg-connect-agent updatestartuptty /bye >/dev/null
                    end

                    # LM Studio CLI
                    set -gx PATH $PATH /Users/guangzong/.lmstudio/bin

                    # OrbStack integration
                    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
                  '';
                };
              };
          }
        ];
      };
    };
}
