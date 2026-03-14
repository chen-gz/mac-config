{ pkgs, lib, ... }:
{
  # 确保 sockets 目录存在
  home.file.".ssh/sockets/.keep".text = "";

  programs.ssh = {
    enable = true;
    # Disable default values that will be removed in the future
    # and manually set the defaults we need in matchBlocks
    enableDefaultConfig = false;
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
