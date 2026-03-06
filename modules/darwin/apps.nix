{ ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [
      "mas"
    ]; # Mac App Store CLI
    taps = [
      "homebrew/cask"
      # "homebrew/cask-fonts" # 如果你还装了字体
    ];
    casks = [
      "steam"
      "antigravity"
      "google-chrome"
      "sublime-merge"
      "raycast"
      "discord"
      "iina"
      "google-drive"
      "wechat"
      "lm-studio"
      "ghostty"
      "zed"
      "db-browser-for-sqlite"
      "stats"
      "monitorcontrol"
      "fluor"
      "jordanbaird-ice"
    ];
    masApps = {
      # "Telegram Lite" = 946399090; # Removed due to mas CLI download issues during automated deployment
      # "Tailscale" = 1475387142; # Removed due to mas CLI download issues during automated deployment
    };
  };
}
