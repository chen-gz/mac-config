{ ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [ "mas" ]; # Mac App Store CLI
    casks = [
      "google-chrome"
      "raycast"
      "discord"
      "iina"
      "iterm2"
      "google-drive"
      "wechat"
      "lm-studio"
      "marta"
      "alacritty"
      "ghostty"
      "db-browser-for-sqlite"
      "stats"
    ];
    masApps = {
      "Telegram Lite" = 946399090;
      "Tailscale" = 1475387142;
    };
  };
}
