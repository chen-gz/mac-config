{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    prefix = "C-a";
    extraConfig = ''
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      bind C-a send-prefix
      unbind C-b

      # Smart pane switching with awareness of Helix splits
      # is_helix="ps -o state= -o comm= -t '#{pane_tty}' \
      #    | grep -iqE '^[^TXZ ]+ +(\S+\/)?(hx|helix)$'"

      # bind-key -n 'C-h' if-shell "$is_helix" 'send-keys C-h'  'select-pane -L'
      # bind-key -n 'C-j' if-shell "$is_helix" 'send-keys C-j'  'select-pane -D'
      # bind-key -n 'C-k' if-shell "$is_helix" 'send-keys C-k'  'select-pane -U'
      # bind-key -n 'C-l' if-shell "$is_helix" 'send-keys C-l'  'select-pane -R'

      # 直接使用 Ctrl-hjkl 切换 tmux 面板
      bind-key -n 'C-h' select-pane -L
      bind-key -n 'C-j' select-pane -D
      bind-key -n 'C-k' select-pane -U
      bind-key -n 'C-l' select-pane -R

      # 针对 Helix 的性能优化
      set -sg escape-time 0
      set -g focus-events on

      # 开启真彩色支持
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"
    '';
  };
}
