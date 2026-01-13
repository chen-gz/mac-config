{ pkgs, username, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # 将核心 CLI 工具放入系统包中，确保 PATH 始终能找到它们
  environment.systemPackages = with pkgs; [
    fish
    git
  ];

  nix.settings = {
    experimental-features = "nix-command flakes";
    # Optimize for nix-direnv
    keep-outputs = true;
    keep-derivations = true;
  };

  system.primaryUser = username;

  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  environment.shells = [ pkgs.fish ];

  system.activationScripts.preActivation = {
    enable = true;
    text = ''
      if [ -f /etc/shells ] && [ ! -L /etc/shells ]; then
        echo "Backing up /etc/shells to /etc/shells.before-nix-darwin"
        sudo mv /etc/shells /etc/shells.before-nix-darwin
      fi
      if [ -f /etc/bashrc ] && [ ! -L /etc/bashrc ]; then
        echo "Backing up /etc/bashrc to /etc/bashrc.before-nix-darwin"
        sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
      fi
      if [ -f /etc/zshrc ] && [ ! -L /etc/zshrc ]; then
        echo "Backing up /etc/zshrc to /etc/zshrc.before-nix-darwin"
        sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
      fi

      # Force update user shell to nix-managed fish
      if [ "$(dscl . -read /Users/${username} UserShell | awk '{print $2}')" != "/run/current-system/sw/bin/fish" ]; then
        echo "Updating user shell to /run/current-system/sw/bin/fish"
        sudo dscl . -create /Users/${username} UserShell /run/current-system/sw/bin/fish
      fi
    '';
  };

  users.users."${username}" = {
    home = "/Users/${username}";
    shell = pkgs.fish;
  };
  # users.users."${username}".home = "/Users/${username}";

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;

    # iTerm2 配置重定向
    CustomUserPreferences = {
      "com.googlecode.iterm2" = {
        PrefsCustomFolder = "~/.config/nix-darwin/iterm2";
        LoadPrefsFromCustomFolder = true;
      };
    };
  };

  system.stateVersion = 5;

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
