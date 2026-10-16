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
      "duckduckgo"
      "jellyfin-media-player"
      "iina"
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
      "codex"
      "obs"
      "signal"
      "visual-studio-code"
      "linear"
    ];
    masApps = {
    };
  };
}
