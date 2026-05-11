{ pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
    };
  };

  home.file = {
    ".gnupg/gpg-agent.conf".text = ''
      enable-ssh-support
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
      default-cache-ttl 259200
      max-cache-ttl 259200
      default-cache-ttl-ssh 259200
      max-cache-ttl-ssh 259200
      allow-loopback-pinentry
      allow-preset-passphrase
      no-grab
    '';
    ".gnupg/scdaemon.conf".text = ''
      # Use macOS native smartcard services
      disable-ccid
    '';
  };
}
