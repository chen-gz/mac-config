{
  pkgs,
  lib,
  config,
  hostname,
  ...
}:
{
  # --- 系统层配置 (仅对 macOS 生效) ---
  system.defaults = {
    dock.orientation = "left";
  };

  # --- 用户层配置 (Home Manager) ---
  home-manager.users.guangzong = {
    imports = [
      ./modules/home.nix
    ];

    programs.git.settings.user = {
      name = "Guangzong Chen";
      email = "guangzong@google.com";
      signingkey = "20AE4BA8FF696FB5E21AE9D0636538D58AF1006D";
    };

    programs.fish.shellAliases = {
      gg_update = "~/.config/nix-darwin/zig-out/bin/bootstrap update && ~/.config/nix-darwin/zig-out/bin/bootstrap deploy ${hostname}";
      gg_deploy = "~/.config/nix-darwin/zig-out/bin/bootstrap deploy ${hostname}";
      gg_clean = "~/.config/nix-darwin/zig-out/bin/bootstrap clean";
    };

    # Sequoia/GPG activation
    home.activation = {
      importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GPG_KEY_ID="20AE4BA8FF696FB5E21AE9D0636538D58AF1006D"
        # 使用 Sequoia 的 chameleon 接口替代原生 gpg
        $DRY_RUN_CMD ${pkgs.sequoia-chameleon-gnupg}/bin/gpg --list-keys $GPG_KEY_ID >/dev/null 2>&1 || 
          $DRY_RUN_CMD ${pkgs.sequoia-chameleon-gnupg}/bin/gpg --keyserver hkps://keys.openpgp.org --recv-keys $GPG_KEY_ID

        # Set ultimate trust (Sequoia Chameleon 会尽量兼容这些操作)
        echo "$GPG_KEY_ID:6:" | $DRY_RUN_CMD ${pkgs.sequoia-chameleon-gnupg}/bin/gpg --import-ownertrust
      '';
    };
  };
}
