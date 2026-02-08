{ pkgs, ... }:
{
  # 确保 sockets 目录存在
  home.file.".ssh/sockets/.keep".text = "";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identityFile = [
        "~/.ssh/id_ed25519_sk"
        "~/.ssh/id_ed25519_sk_rk_ggzongchen@gmail.com"
      ];
      extraOptions = {
        ControlMaster = "auto";
        ControlPersist = "24h";
        ControlPath = "~/.ssh/sockets/%r@%h-%p";
      };
    };
  };
}
