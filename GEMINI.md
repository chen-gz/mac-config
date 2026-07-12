# Project Instructions

- This project uses **Jujutsu (jj)** as the version control system. 
- Use `jj` for all version control operations.
- Prefer `jj git clone <url>` over `git clone <url>` for initial setup.
- **Versioning & Tagging Rules**:
  - Only generate a new version tag after modifying `bootstrap.zig` and ensuring tests pass (modifying Nix configuration files alone does not require a new tag).
  - **Control Tag Frequency**: When modifying `bootstrap.zig` multiple times in a single development session or task, only a single, consolidated new tag should be generated after the final version passes tests, rather than tagging every intermediate commit.
  - **Follow Semantic Versioning (SemVer)**: Use the `vMAJOR.MINOR.PATCH` format (e.g., `v1.3.1`):
    - **MAJOR**: Significant rewrite or breaking changes, which must be explicitly specified by the user.
    - **MINOR**: New features or support for new devices added to `bootstrap.zig` (e.g., upgrading from `v1.3` to `v1.4`).
    - **PATCH**: Bug fixes, robustness improvements, or minor adjustments to `bootstrap.zig` (e.g., upgrading to `v1.3.1` instead of skipping versions).
  - Before generating a new tag, always check existing tags using `git tag -l` or `jj tag list` to increment the version correctly.
- **Voice-to-Text Input Tolerance**: The user dictates requests using voice-to-text, which can introduce typos, grammatical errors, homophones, or mispronounced/poorly transcribed words. The AI must be highly tolerant of these transcription errors, look past surface-level mistakes, and make a best-effort attempt to understand the user's true underlying intent. If the input is completely garbled, ambiguous, or lacks critical context such that it is confusing or impossible to determine the intended action, the AI should ask the user for clarification instead of guessing or making assumptions.



## Project Structure

This repository configures macOS using Nix-Darwin and Home Manager. Below is the project structure for reference:

- **`flake.nix`**: The Nix Flake entrypoint. Defines the Nix-Darwin host configurations (`gg-mac-mini`, `gg-mac-air`) and orchestrates module imports.
- **`guangzong.nix`**: User-specific configuration for `guangzong`. Manages user-level packages, custom Fish aliases, SSH match blocks, and Sequoia GPG import scripts.
- **`bootstrap.zig`**: A helper tool written in Zig used to bootstrap, check, format, update, clean, and deploy the system configuration.
- **`build.zig` / `build.zig.zon`**: Zig compilation settings for the bootstrap tool.
- **`modules/`**: Submodules imported via the Home Manager and Nix-Darwin profiles:
  - **`home.nix`**: Main Home Manager entrypoint. Sets up home state version, global shell session variables, and imports all other user modules.
  - **`darwin.nix`**: Core Nix-Darwin system configuration, Homebrew integrations, and default Nix shell setups.
  - **`system.nix`**: macOS system defaults, Dock configurations, Finder, login options, and user preferences.
  - **`homebrew.nix`**: Homebrew configuration, taps, casks, and Mac App Store apps.
  - **`media.nix`**: Machine-specific media stack configuration (Radarr, Sonarr, Prowlarr, SABnzbd, Bazarr, Caddy, and local hosts redirection).
  - **`nix-packages.nix`**: User-specific Nix package listings.
  - **`git.nix`**: Git, Delta diff viewer, and Lazygit configurations.
  - **`jujutsu.nix`**: Jujutsu (`jj`) configurations, custom GPG signing options, and Delta formatting settings.
  - **`fish.nix` / `tmux.nix`**: Shell alias, function, and window multiplexer setups.
  - **`helix.nix` / `ghostty.nix`**: Helix editor config and Ghostty terminal settings.
  - **`gpg.nix` / `tools.nix`**: CLI utility tools (zoxide, fzf, starship, eza, ripgrep, jq, bottom, bat, etc.) and GPG agent setup.

