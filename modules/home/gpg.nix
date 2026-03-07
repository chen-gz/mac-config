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
      default-cache-ttl 34560000
      max-cache-ttl 34560000
      default-cache-ttl-ssh 34560000
      max-cache-ttl-ssh 34560000
    '';
  };
}
