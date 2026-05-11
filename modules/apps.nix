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
      # Taps are managed by nix-homebrew in common.nix
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
      "ollama"
      "ghostty"
      "zed"
      "db-browser-for-sqlite"
      "stats"
      "monitorcontrol"
      "fluor"
      "jordanbaird-ice"
      # "tailscale"
      "telegram"
    ];
    masApps = {
    };
  };
}
