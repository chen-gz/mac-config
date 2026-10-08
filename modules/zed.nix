{ ... }:
{
  xdg.configFile."zed/settings.json" = {
    force = true;
    text = ''
      {
        "format_on_save": "off",
        "completions": {
          "lsp": false
        },
        "languages": {
          "Nix": {
            "language_servers": [
              "nil",
              "!nixd"
            ]
          }
        },
        "agent_servers": {
          "antigravity-acp": {
            "favorite_config_option_values": {
              "model": [
                "gemini-3.8-flash-high"
              ]
            },
            "default_config_options": {
              "mode": "yolo",
              "model": "gemini-3.8-flash-high"
            },
            "type": "registry"
          }
        },
        "helix_mode": true,
        "base_keymap": "VSCode",
        "icon_theme": {
          "mode": "dark",
          "light": "Zed (Default)",
          "dark": "Zed (Default)"
        },
        "ui_font_size": 16,
        "buffer_font_size": 15,
        "theme": {
          "mode": "dark",
          "light": "One Light",
          "dark": "One Dark"
        }
      }
    '';
  };
}
