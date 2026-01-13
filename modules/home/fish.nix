{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    shellAliases = {
      cat = "bat";
      g = "git";
      vi = "hx";
      vim = "hx";
      lg = "lazygit";
      blog = "cd ~/Documents/chen-gz.github.io";
      nixconf = "cd ~/.config/nix-darwin && hx flake.nix";
      nsw = "sudo -H nix run nix-darwin -- switch --flake ~/.config/nix-darwin#guangzong-mac-mini";
    };

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
      end

      pay-respects setup --shell fish | source

      set -gx PATH $PATH $HOME/.lmstudio/bin
      source ~/.orbstack/shell/init2.fish 2>/dev/null || :
    '';
  };
}
