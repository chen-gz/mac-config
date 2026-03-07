{ pkgs, lib, ... }:
{
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
  };

  # SSH specific to guangzong
  programs.ssh.matchBlocks = lib.mkIf pkgs.stdenv.isDarwin {
    "10.0.0.107" = {
      hostname = "10.0.0.107";
      user = "connie";
      forwardAgent = true;
      extraOptions = {
        RemoteForward = "/Users/connie/.gnupg/S.gpg-agent /Users/guangzong/.gnupg/S.gpg-agent.extra
        RemoteForward /Users/connie/.gnupg/S.gpg-agent.ssh.forward /Users/guangzong/.gnupg/S.gpg-agent.ssh";
        StreamLocalBindUnlink = "yes";
      };
    };
  };

  # GPG activation specific to guangzong
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.activation = {
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
