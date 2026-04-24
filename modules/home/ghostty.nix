{ pkgs, lib, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isDarwin {
      xdg.configFile."ghostty/config".text = ''
        background-opacity = 0.90
        background-blur = true
        window-padding-x = 10
        window-padding-y = 10
      '';
    })
    (lib.mkIf pkgs.stdenv.isLinux {
      xdg.configFile."ghostty/config".text = ''
        background-opacity = 0.90
        background-blur = true
        window-padding-x = 10
        window-padding-y = 10
        # Change shortcuts to be the same as macos in linux enviroment
        font-size=14

        keybind = super+c=copy_to_clipboard
        keybind = super+v=paste_from_clipboard
        keybind = super+k=clear_screen
        keybind = super+plus=increase_font_size:1
        keybind = super+minus=decrease_font_size:1
        keybind = super+0=reset_font_size
        keybind = super+page_up=scroll_page_up
        keybind = super+page_down=scroll_page_down
        keybind = super+n=new_window
        keybind = super+t=new_tab
        keybind = super+w=close_surface
        keybind = ctrl+tab=next_tab
        keybind = ctrl+shift+tab=previous_tab
        keybind = super+1=goto_tab:1
        keybind = super+2=goto_tab:2
        keybind = super+3=goto_tab:3
        keybind = super+4=goto_tab:4
        keybind = super+5=goto_tab:5
        keybind = super+6=goto_tab:6
        keybind = super+7=goto_tab:7
        keybind = super+8=goto_tab:8
        keybind = super+9=goto_tab:9

        keybind = super+shift+[=move_tab:-1
        keybind = super+shift+]=move_tab:1
      '';
    })
  ];
}