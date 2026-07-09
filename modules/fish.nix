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
      G = "agy";
      gemini = "agy";
      vi = "hx";
      lg = "lazygit";
      lj = "lazyjj";
      nixconf = "cd ~/.config/nix-darwin";

      push = "if test (jj log -r @ --no-graph -T empty) = true; jj bookmark set main -r @-; else; jj bookmark set main -r @; end; and jj git push";
      dr = "devenv tasks run";
      ds = "devenv shell";
      top = "btop";
      jq = "jql";
      df = "duf";
      du = "dust";
      man = "tldr";
      hexdump = "hexyl";
      gpgrestart = "gpg-connect-agent reloadagent /bye && ssh-add -D";
      clean = "atuin search --exclude-exit=0 \"\" --delete";
      dcgen = "devenv eval devcontainer.settings | jq '\"devcontainer.settings\"' > .devcontainer.json";

      # Media Stack Services Control
      radarr-start = "launchctl bootstrap gui/(id -u) ~/Library/LaunchAgents/org.nixos.radarr.plist";
      radarr-stop = "launchctl bootout gui/(id -u) ~/Library/LaunchAgents/org.nixos.radarr.plist";
      sonarr-start = "launchctl bootstrap gui/(id -u) ~/Library/LaunchAgents/org.nixos.sonarr.plist";
      sonarr-stop = "launchctl bootout gui/(id -u) ~/Library/LaunchAgents/org.nixos.sonarr.plist";
      prowlarr-start = "launchctl bootstrap gui/(id -u) ~/Library/LaunchAgents/org.nixos.prowlarr.plist";
      prowlarr-stop = "launchctl bootout gui/(id -u) ~/Library/LaunchAgents/org.nixos.prowlarr.plist";
      sabnzbd-start = "launchctl bootstrap gui/(id -u) ~/Library/LaunchAgents/org.nixos.sabnzbd.plist";
      sabnzbd-stop = "launchctl bootout gui/(id -u) ~/Library/LaunchAgents/org.nixos.sabnzbd.plist";

      # Direct foreground running
      radarr-run = "/Applications/Radarr.app/Contents/MacOS/Radarr -nobrowser";
      sonarr-run = "/Applications/Sonarr.app/Contents/MacOS/Sonarr -nobrowser";
      prowlarr-run = "/Applications/Prowlarr.app/Contents/MacOS/Prowlarr -nobrowser";
      sabnzbd-run = "/Applications/SABnzbd.app/Contents/MacOS/SABnzbd --browser 0";
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

      # Homebrew setup
      if test -d /opt/homebrew/bin
          eval (/opt/homebrew/bin/brew shellenv)
      else if test -d /usr/local/bin
          eval (/usr/local/bin/brew shellenv)
      end
      set -x GPG_TTY (tty)
      if test -n "$SSH_CONNECTION"
          # We are on the remote host via SSH: use the forwarded fixed socket path
          set -x SSH_AUTH_SOCK ~/.gnupg/S.gpg-agent.ssh.forward
      else
          # Local Mac
          set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
      end

      pay-respects setup --shell fish | source

      set -gx PATH $PATH $HOME/.lmstudio/bin
      source ~/.orbstack/shell/init2.fish 2>/dev/null || :
    '';
  };
}
