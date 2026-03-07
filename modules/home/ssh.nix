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
    };
  };
}
