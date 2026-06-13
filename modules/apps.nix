{ ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [
      "mas"
    ]; # Mac App Store CLI
    taps = [
    ];
    casks = [
      # "steam"
      "google-chrome"
      "jellyfin-media-player"
      "raycast"
      "iina"
      "google-drive"
      "wechat"
      "ollama-app"
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
    ];
    masApps = {
    };
  };
}
