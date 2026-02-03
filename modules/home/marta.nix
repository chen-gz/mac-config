{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.file."Library/Application Support/org.yanex.marta/conf.json".text = builtins.toJSON {
      fonts = {
        normal = [ "JetBrainsMono Nerd Font" 14 ];
      };
    };
  };
}