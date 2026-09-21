{ ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [
      "kcov"
    ];
    taps = [
    ];
    casks = [
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
      "antigravity"
      "antigravity-cli"
      "obs"
      "signal"
      "visual-studio-code"
    ];
    masApps = {
    };
  };
}
