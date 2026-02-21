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
    casks = [
      "google-chrome"
      "raycast"
      "discord"
      "iina"
      "google-drive"
      "wechat"
      "lm-studio"
      "marta"
      "alacritty"
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
