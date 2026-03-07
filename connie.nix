{ pkgs, lib, ... }:
{
  # --- 系统层配置 (仅对 macOS 生效) ---
  system.defaults.dock.autohide = lib.mkForce true;

  # --- 用户层配置 (Home Manager) ---
  home-manager.users.connie = {
    imports = [
      ./modules/home/common.nix
    ];

    programs.fish.shellAliases = {
      connie_update = "~/.config/nix-darwin/bootstrap.sh update && ~/.config/nix-darwin/bootstrap.sh deploy connie-mac";
    };

    programs.git.settings = {
      user = {
        name = "Connie";
        email = "connie@ggeta.com";
        signingkey = "F44759AD8A47152383AB4CA5F8FEDE944102385C";
      };
      commit = {
        gpgsign = lib.mkForce true;
      };
    };

    # GPG activation specific to connie
    home.activation = lib.mkIf pkgs.stdenv.isDarwin {
      importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GPG_KEY_ID="F44759AD8A47152383AB4CA5F8FEDE944102385C"
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --list-keys $GPG_KEY_ID >/dev/null 2>&1 || 
          $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys $GPG_KEY_ID

        # Set ultimate trust for the key
        echo "$GPG_KEY_ID:6:" | $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import-ownertrust
      '';
    };
  };
}
