{
  pkgs,
  lib,
  config,
  ...
}:
{
  # --- 系统层配置 (仅对 macOS 生效) ---
  # 只有在 nix-darwin 环境下才定义 system.defaults
  system.defaults.dock.orientation = "left";

  # --- 用户层配置 (Home Manager) ---
  home-manager.users.guangzong = {
    imports = [
      ./modules/home/common.nix
    ];

    programs.git.settings.user = {
      name = "Guangzong Chen";
      email = "guangzong@google.com";
      signingkey = "20AE4BA8FF696FB5E21AE9D0636538D58AF1006D";
    };

    programs.fish.shellAliases = {
      blog = "cd ~/Documents/chen-gz.github.io";
      cf = "cd ~/Documents/cf_template && hx main.cpp";
      gg_update = "~/.config/nix-darwin/bootstrap.sh update && ~/.config/nix-darwin/bootstrap.sh deploy gg-mac";

    };

    # SSH specific to guangzong
    programs.ssh.matchBlocks = lib.mkIf pkgs.stdenv.isDarwin {
      "connie" = {
        hostname = "connies-mac-mini";
        user = "connie";
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = "/Users/connie/.gnupg/S.gpg-agent";
            host.address = "/Users/guangzong/.gnupg/S.gpg-agent.extra";
          }
          {
            bind.address = "/Users/connie/.gnupg/S.gpg-agent.ssh.forward";
            host.address = "/Users/guangzong/.gnupg/S.gpg-agent.ssh";
          }
        ];
        extraOptions = {
          StreamLocalBindUnlink = "yes";
        };
      };
      "10.0.0.107" = {
        hostname = "10.0.0.107";
        user = "connie";
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = "/Users/connie/.gnupg/S.gpg-agent";
            host.address = "/Users/guangzong/.gnupg/S.gpg-agent.extra";
          }
          {
            bind.address = "/Users/connie/.gnupg/S.gpg-agent.ssh.forward";
            host.address = "/Users/guangzong/.gnupg/S.gpg-agent.ssh";
          }
        ];
        extraOptions = {
          StreamLocalBindUnlink = "yes";
        };
      };
    };
    # GPG activation specific to guangzong
    home.activation = lib.mkIf pkgs.stdenv.isDarwin {
      importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GPG_KEY_ID="20AE4BA8FF696FB5E21AE9D0636538D58AF1006D"
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --list-keys $GPG_KEY_ID >/dev/null 2>&1 || 
          $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --keyserver hkps://keys.openpgp.org --recv-keys $GPG_KEY_ID

        # Set ultimate trust for the key
        echo "$GPG_KEY_ID:6:" | $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import-ownertrust
      '';
    };
  };
}
