{ ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [
      "kcov"
    ]; # Mac App Store CLI
    taps = [
    ];
    casks = [
      # "steam"
      "google-chrome"
      "jellyfin-media-player"
      "raycast"
      "google-drive"
      "wechat"
      "ghostty"
      "zed"
      "db-browser-for-sqlite"
      "stats"
      "monitorcontrol"
      "fluor"
      "jordanbaird-ice"
      "tailscale"
      "telegram"
      "bitwarden"
      "antigravity-cli"
      "lm-studio"
    ];
    masApps = {
    };
  };
}
