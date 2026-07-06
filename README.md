# Mac Config

My macOS configuration managed by Nix-Darwin.

## Installation

### One-command Setup (Recommended)

Run the following command to bootstrap your environment automatically. This will install Nix, clone this repository, and deploy the configuration.

For **Mac Mini** (`gg-mac-mini`):
```bash
curl -L -O https://github.com/chen-gz/mac-config/releases/latest/download/bootstrap && chmod +x bootstrap && ./bootstrap gg-mac-mini
```

For **MacBook Air** (`gg-mac-air`):
```bash
curl -L -O https://github.com/chen-gz/mac-config/releases/latest/download/bootstrap && chmod +x bootstrap && ./bootstrap gg-mac-air
```

### Manual Installation

If you prefer to build the bootstrap tool from source using Zig:

```bash
git clone https://github.com/chen-gz/mac-config.git ~/.config/nix-darwin
cd ~/.config/nix-darwin
# For guangzong-mac-mini
zig build run -- gg-mac-mini
# For guangzong-mac-air
zig build run -- gg-mac-air
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

## Keybindings & Aliases (快捷键与别名)

For a complete and detailed list of preset shortcuts, see [keyboard.md](keyboard.md). Below is a quick summary of the core presets:

- **Tmux Navigation**: Prefix key is mapped to `Ctrl + a`. Direct pane switching using `Ctrl + h/j/k/l` (no prefix required).
- **Helix Editor**: Press `jj` or `jk` in insert mode to return to normal mode; `q` in normal mode quits.
- **Fish Shell**: Highly productive aliases like `vi` (`hx`), `lg` (`lazygit`), `lj` (`lazyjj`), and a smart directory navigator `y` (`yazi`).
- **Fish & FZF Helpers**: Use `Alt + c` to search/cd into subdirectories, `Alt + l` to list directory contents, and `Alt + d` to delete the next word or list history.
- **Antigravity CLI**: Preset keybindings for AI coding workspace management, including `Ctrl + k` (approve subagent) and `Ctrl + o` (toggle trajectory panel).

