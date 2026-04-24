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
        tweak-graphemes-like-iterm=true

        key-quit=none
        key-copy="Command|c"
        key-paste="Command|v"
        key-clear-history="Command|k"
        key-zoom-in="Command|plus"
        key-zoom-out="Command|minus"
        iec-style-word-movement=true
        key-reset-zoom="Command|0"
        key-page-up="Command|PageUp"
        key-page-down="Command|PageDown"
        key-open-link="Command|l"
        key-increase-font-size="Command|="
        key-decrease-font-size="Command|-"
        key-reset-font-size="Command|0"
        key-new-window="Command|n"
        key-new-tab="Command|t"
        key-close-tab="Command|w"
        key-next-tab="Control|Tab"
        key-previous-tab="Control|Shift|Tab"
        key-set-tab-1="Command|1"
        key-set-tab-2="Command|2"
        key-set-tab-3="Command|3"
        key-set-tab-4="Command|4"
        key-set-tab-5="Command|5"
        key-set-tab-6="Command|6"
        key-set-tab-7="Command|7"
        key-set-tab-8="Command|8"
        key-set-tab-9="Command|9"

        key-move-tab-prev="Command|{"
        key-move-tab-next="Command|}"
      '';
    })
  ];
}
