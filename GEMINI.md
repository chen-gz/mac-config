# Project Instructions

- This project uses **Jujutsu (jj)** as the version control system. 
- Use `jj` for all version control operations.
- Prefer `jj git clone <url>` over `git clone <url>` for initial setup.
- Always create a new version tag (e.g., `v1.1`, `v1.2`) whenever `bootstrap.zig` is modified.
- When creating a new version tag, check the previous version tags first.
- For major/big updates, the user will explicitly specify the version number.

## Project Structure

This repository configures macOS using Nix-Darwin and Home Manager. Below is the project structure for reference:

- **`flake.nix`**: The Nix Flake entrypoint. Defines the Nix-Darwin host configurations (`gg-mac-mini`, `gg-mac-air`, `connie-mac`) and orchestrates module imports.
- **`guangzong.nix`**: User-specific configuration for `guangzong`. Manages user-level packages, custom Fish aliases, SSH match blocks, and Sequoia GPG import scripts.
- **`connie.nix`**: User-specific configuration for `connie`.
- **`bootstrap.zig`**: A helper tool written in Zig used to bootstrap, check, format, update, clean, and deploy the system configuration.
- **`build.zig` / `build.zig.zon`**: Zig compilation settings for the bootstrap tool.
- **`modules/`**: Submodules imported via the Home Manager and Nix-Darwin profiles:
  - **`home.nix`**: Main Home Manager entrypoint. Sets up home state version, global shell session variables, and imports all other user modules.
  - **`darwin.nix`**: Core Nix-Darwin system configuration, Homebrew integrations, and default Nix shell setups.
  - **`system.nix`**: macOS system defaults, Dock configurations, Finder, login options, and user preferences.
  - **`apps.nix`**: System-level applications.
  - **`media.nix`**: Machine-specific media stack configuration (Radarr, Sonarr, Prowlarr, SABnzbd, Bazarr, Caddy, and local hosts redirection).
  - **`packages.nix`**: User-specific package listings.
  - **`git.nix`**: Git, Delta diff viewer, and Lazygit configurations.
  - **`jujutsu.nix`**: Jujutsu (`jj`) configurations, custom GPG signing options, and Delta formatting settings.
  - **`fish.nix` / `tmux.nix`**: Shell alias, function, and window multiplexer setups.
  - **`helix.nix` / `ghostty.nix`**: Helix editor config and Ghostty terminal settings.
  - **`gpg.nix` / `tools.nix`**: CLI utility tools (zoxide, fzf, starship, eza, ripgrep, jq, bottom, bat, etc.) and GPG agent setup.

