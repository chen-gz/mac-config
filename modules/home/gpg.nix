{ pkgs, lib, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
    };
  };

  home.file = {
    ".gnupg/gpg-agent.conf".text =
      let
        pinentry =
          if pkgs.stdenv.isDarwin then
            "${pkgs.pinentry_mac}/bin/pinentry-mac"
          else
            # A sensible default for Linux. You might want to change it.
            # pkgs.pinentry-qt, pkgs.pinentry-curses, etc. are also available.
            "${pkgs.pinentry-curses}/bin/pinentry";
      in
      ''
        enable-ssh-support
        pinentry-program ${pinentry}
        default-cache-ttl 259200
        max-cache-ttl 259200
        default-cache-ttl-ssh 259200
        max-cache-ttl-ssh 259200
        allow-loopback-pinentry
        allow-preset-passphrase
        no-grab
      '';
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    ".gnupg/scdaemon.conf".text = ''
      # Use macOS native smartcard services
      disable-ccid
    '';
  };
}
