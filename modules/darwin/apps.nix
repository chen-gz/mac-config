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
      "google-chrome"
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
      "Telegram Lite" = 946399090;
      "Tailscale" = 1475387142;
    };
  };
}
