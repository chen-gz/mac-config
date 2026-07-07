# Project Instructions

- This project uses **Jujutsu (jj)** as the version control system. 
- Use `jj` for all version control operations.
- Prefer `jj git clone <url>` over `git clone <url>` for initial setup.
- **版本与 Tag 规范 (Versioning & Tagging Rules)**:
  - 只有在修改 `bootstrap.zig` 且测试通过后，才生成新的版本 Tag（仅修改 Nix 配置文件本身不需要生成 Tag）。
  - **控制 Tag 增长频率**：在单次开发任务或同一会话中多次修改 `bootstrap.zig` 时，应当在最终交付、通过测试后仅生成**一个**合并后的新 Tag，避免对每一个中间 commit 频繁打 Tag。
  - **遵循语义化版本 (SemVer) 规范**：使用 `vMAJOR.MINOR.PATCH` 格式（如 `v1.3.1`）：
    - **MAJOR (主版本)**：重大重构或破坏性变更，需由用户明确指定。
    - **MINOR (次版本)**：对 `bootstrap.zig` 添加了新功能或新增支持设备（例如从 `v1.3` 升级到 `v1.4`）。
    - **PATCH (修订版)**：对 `bootstrap.zig` 的 Bug 修复、健壮性优化或微调（应升级为 `v1.3.1`，避免跳版本）。
  - 在生成新 Tag 前，务必先通过 `git tag -l` 或 `jj tag list` 检查已有版本以正确递增。

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

