{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    programs.gpg = {
      enable = true;
      settings = {
        keyserver = "hkps://keys.openpgp.org";
      };
    };

    # gpg-agent configuration for macOS
    home.file.".gnupg/gpg-agent.conf".text = ''
      enable-ssh-support
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
      default-cache-ttl 86400
      max-cache-ttl 86400
    '';

    home.activation = {
      importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GPG_KEY_ID="20AE4BA8FF696FB5E21AE9D0636538D58AF1006D"
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --list-keys $GPG_KEY_ID >/dev/null 2>&1 || \
          $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --keyserver hkps://keys.openpgp.org --recv-keys $GPG_KEY_ID

        # Set ultimate trust for the key
        echo "$GPG_KEY_ID:6:" | $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import-ownertrust
      '';
    };
  };
}
