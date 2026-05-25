# Mac Config

My macOS configuration managed by Nix-Darwin.

## Installation

### One-command Setup (Recommended)

Run the following command to bootstrap your environment automatically. This will install Nix, clone this repository, and deploy the configuration:

```bash
curl -L -O https://github.com/chen-gz/mac-config/releases/latest/download/bootstrap && chmod +x bootstrap && ./bootstrap gg-mac
```

### Manual Installation

If you prefer to build the bootstrap tool from source using Zig:

```bash
git clone https://github.com/chen-gz/mac-config.git ~/.config/nix-darwin
cd ~/.config/nix-darwin
# For guangzong-mac
zig build run -- gg-mac
# For connie-mac
zig build run -- connie-mac
```
## Features

- **Nix-Darwin & Home Manager**: Unified system and user-level configuration.
- **Agentic Workflow**: Integrated with `gemini` and `antigravity` using custom global rules.
- **Jujutsu (jj)**: Modern version control with automatic snapshots and TUI support via `lazyjj`.
- **Fish Shell**: Optimized shell with productive aliases (`lg` for lazygit, `lj` for lazyjj).
- **Editor**: Helix (`hx`) as the primary editor.

## Agent Rules

This project enforces a structured agentic workflow defined in `~/.gemini/GEMINI.md`:
1. Always use `jj` for version control.
2. Automatic `jj log` snapshots after any file modification.
3. Logical task summaries via `jj describe` upon completion.

