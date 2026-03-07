{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    programs.alacritty = {
      enable = true;
      settings = {
        window.padding = {
          x = 10;
          y = 10;
        };
        font = {
          normal.family = "JetBrainsMono Nerd Font";
          size = 16;
        };
      };
    };
  };
}
