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
      # 配置格式化工具，修复 nix fmt 报错
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

              # 禁用系统级 Shell 管理以避免修改 /etc/bashrc 和 /etc/zshrc
              programs.bash.enable = false;
              programs.zsh.enable = false;
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
            home-manager.users."${username}" =
              { pkgs, ... }:
              {
                home.stateVersion = "25.11";

                home.packages = with pkgs; [
                  fzf
                  ripgrep
                ];

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

                # --- 重点：Fish 用户配置 ---
                programs.fish = {
                  enable = true;

                  # 别名设置：将原有的 alias 迁移至此
                  shellAliases = {
                    cat = "bat";
                    g = "git";
                    vi = "nvim";
                    cdd = "cd ~/Documents";
                    nixconf = "cd ~/.config/nix-darwin && nvim flake.nix";
                  };

                  # 交互式 Shell 初始化：保留必要的运行时配置
                  interactiveShellInit = ''
                    # 设置 Fish 欢迎语为空
                    set -g fish_greeting ""

                    # 额外的 PATH 设置 (Nix 未覆盖的部分)
                    fish_add_path ~/.local/bin
                    fish_add_path ~/.cargo/bin
                    
                    # FZF 初始化
                    fzf --fish | source

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
