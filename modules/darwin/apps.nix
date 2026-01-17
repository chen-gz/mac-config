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
    ];
    masApps = {
      "Telegram Lite" = 946399090;
    };
  };
}
