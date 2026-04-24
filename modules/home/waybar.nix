{ lib, pkgs, ... }:

{
  # Waybar configuration for Linux
  programs.waybar = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "memory" "cpu" "clock" ];
        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
        };
        "memory" = {
          format = " {}%";
        };
        "cpu" = {
          format = " {}%";
        };
        "clock" = {
          format-alt = "{:%Y-%m-%d}";
        };
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }
      window#waybar {
        background: #282828;
        color: #ebdbb2;
      }
      #workspaces button {
        padding: 0 5px;
        background: #282828;
        color: #ebdbb2;
      }
      #workspaces button.active {
        background: #ebdbb2;
        color: #282828;
      }
    '';
  };
}
