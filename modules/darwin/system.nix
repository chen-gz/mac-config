{ pkgs, username, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # 将核心 CLI 工具放入系统包中，确保 PATH 始终能找到它们
  environment.systemPackages = with pkgs; [
    fish
    git
  ];
  nix.enable = false;

  system.primaryUser = username;

  programs.bash.enable = false;
  programs.zsh.enable = false;
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
    dock.autohide = false;
    dock.orientation = "left";
    dock.show-recents = false;
    dock.persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/System/Applications/Mail.app"
      "/Applications/Google Chrome.app"
      "/System/Applications/Calendar.app"
      "/Applications/Ghostty.app"
      "/System/Applications/Photos.app"
    ];
    finder.AppleShowAllExtensions = true;
  };

  system.stateVersion = 5;

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
