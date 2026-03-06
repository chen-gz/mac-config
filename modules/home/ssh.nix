{ pkgs, lib, ... }:
{
  # 确保 sockets 目录存在
  home.file.".ssh/sockets/.keep".text = "";

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          ControlMaster = "auto";
          ControlPersist = "24h";
        };
      };
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      "10.0.0.107" = {
        hostname = "10.0.0.107";
        user = "connie";
        forwardAgent = true;
        extraOptions = {
          # Forward local GPG agent (extra socket) to remote GPG agent (standard socket)
          # Forward local GPG-SSH agent socket to remote GPG-SSH agent socket
          # Note: We use a custom path on the remote to avoid conflicts if the remote agent starts
          RemoteForward = "/Users/connie/.gnupg/S.gpg-agent /Users/guangzong/.gnupg/S.gpg-agent.extra\n          RemoteForward /Users/connie/.gnupg/S.gpg-agent.ssh.forward /Users/guangzong/.gnupg/S.gpg-agent.ssh";
          StreamLocalBindUnlink = "yes";
        };
      };
    };
  };
}
