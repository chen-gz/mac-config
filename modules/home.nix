{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.stateVersion = "24.05";

  programs.git.enable = true;
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
      theme = "TwoDark";
    };
  };

  # --- Lazygit 配置 ---
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showIcons = true;
        skipDiscardChangeWarning = true;
      };
      git.pagers = [
        {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        }
      ];
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    config = {
      global = {
        log_format = "";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        true-color = true;
        line-number = "relative";
        bufferline = "multiple";
        cursorline = true;
        color-modes = true;
        whitespace = {
          render = "all";
          characters = {
            space = " ";
            tab = "→";
            newline = " ";
          };
        };
        indent-guides.render = true;
        file-picker.hidden = false;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        lsp.display-messages = true;
      };
      keys.normal = {
        q = ":quit";
      };
    };
    languages = {
      language = [{
        name = "just";
        auto-format = true;
        language-servers = [ "just-lsp" ];
      }];
      language-server = {
        just-lsp = {
          command = "just-lsp";
        };
      };
    };
  };

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
      is_helix="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?(hx|helix)$'"

      bind-key -n 'C-h' if-shell "$is_helix" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_helix" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_helix" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_helix" 'send-keys C-l'  'select-pane -R'
    '';
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      cat = "bat";
      g = "git";
      vi = "hx";
      vim = "hx";
      lg = "lazygit";
      nixconf = "cd ~/.config/nix-darwin && hx flake.nix"; # Might need adjustment for linux
    } // (if isDarwin then {
      blog = "cd ~/Documents/chen-gz.github.io";
      nsw = "sudo -H nix run nix-darwin -- switch --flake ~/.config/nix-darwin#guangzong-mac-mini";
    } else {});

    interactiveShellInit = ''
      set -g fish_greeting ""
      set -gx DIRENV_LOG_FORMAT ""
      fish_add_path ~/.local/bin
      fish_add_path ~/.cargo/bin
      # 确保 Nix 系统路径在 PATH 中 (防止 Unknown command 报错)
      if not contains /run/current-system/sw/bin $PATH
          fish_add_path --prepend --global /run/current-system/sw/bin
      end

      set -x GPG_TTY (tty)
      if test (uname) = "Darwin"
          set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
          gpg-connect-agent updatestartuptty /bye >/dev/null

          # Mac specific paths
          set -gx PATH $PATH /Users/guangzong/.lmstudio/bin
          source ~/.orbstack/shell/init2.fish 2>/dev/null || :
      end
    '';
  };
}
