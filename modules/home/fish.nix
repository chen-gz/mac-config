{ pkgs, ... }:
{
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons --git";
      # lst = "eza --icons --git --tree";
      cat = "bat";
      gc = "gemini --yolo";
      G = "gemini";
      vi = "hx";
      vim = "hx";
      lg = "lazygit";
      blog = "cd ~/Documents/chen-gz.github.io";
      cf = "cd ~/Documents/cf_template && hx main.cpp";
      nixconf = "cd ~/.config/nix-darwin";
      nsw = "~/.config/nix-darwin/bootstrap.sh deploy";

      # Bootstrap script commands
      deploy = "~/.config/nix-darwin/bootstrap.sh deploy";
      update = "~/.config/nix-darwin/bootstrap.sh update";

      dr = "devbox run";
      ds = "devbox shell";
      top = "btop";
      jq = "jql";
      df = "duf";
      du = "dust";
      man = "tldr";
      hexdump = "hexyl";
      gpgrestart = "gpg-connect-agent reloadagent /bye && ssh-add -D";
      clean = "atuin search --exclude-exit=0 \"\" --delete";
    };

    functions = {
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };

    interactiveShellInit = ''
      set -g fish_greeting ""
      set -g fish_key_bindings fish_default_key_bindings
      set -gx DIRENV_LOG_FORMAT ""
      fish_add_path ~/.local/bin
      fish_add_path ~/.cargo/bin
      # 确保 Nix 系统路径在 PATH 中 (防止 Unknown command 报错)
      if test -d /run/current-system/sw/bin
          fish_add_path --prepend --global /run/current-system/sw/bin
      end

      # On non-NixOS Linux, Home Manager installs packages to ~/.nix-profile/bin
      if test -d ~/.nix-profile/bin
          fish_add_path --prepend --global ~/.nix-profile/bin
      end

      set -x GPG_TTY (tty)
      if test (uname) = "Darwin"

          set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
          gpg-connect-agent updatestartuptty /bye >/dev/null
          # echo "🔒 SSH: Fallback to GPG Agent"
      end

      pay-respects setup --shell fish | source

      set -gx PATH $PATH $HOME/.lmstudio/bin
      source ~/.orbstack/shell/init2.fish 2>/dev/null || :
    '';
  };
}
