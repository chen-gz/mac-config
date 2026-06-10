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
      # "sublime-merge"
      "raycast"
      # "discord"
      "iina"
      "google-drive"
      "wechat"
      # "lm-studio"
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
