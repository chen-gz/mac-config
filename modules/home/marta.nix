{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.file."Library/Application Support/org.yanex.marta/conf.json".text = builtins.toJSON {
      # This sets the font for the main application UI
      fonts = {
        normal = [
          "JetBrainsMono Nerd Font"
          14
        ];
      };
      # This configures the embedded terminal (etty)
      etty = {
        # Fixes shell compatibility issues with fish
        #shell = "/run/current-system/sw/bin/fish";
        # Sets the font for the terminal
        font = [
          "JetBrainsMono Nerd Font"
          14
        ];
      };
    };
  };
}
