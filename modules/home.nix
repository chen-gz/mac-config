{ pkgs, lib, ... }:
{
  imports = [
    ./fish.nix
    ./ghostty.nix
    ./git.nix
    ./gpg.nix
    ./helix.nix
    ./jujutsu.nix
    ./tmux.nix
    ./tools.nix
    ./packages.nix
  ];

  home.stateVersion = "25.11";

  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = "hx";
    VISUAL = "hx";
  };

  fonts.fontconfig.enable = true;

  home.file.".gemini/GEMINI.md".text = ''
    # Global Instructions

    - For both `gemini-cli` and `antigravity`, always run `jj log` immediately after modifying any files to save the current work and maintain visibility of the version control state.
    - Always use `jj` (Jujutsu) for version control operations.
    - Prefer `jj git clone <url>` over `git clone <url>` for initial setup.
    - Upon completing a logical task or a significant phase, always use `jj describe -m "..."` to provide a clear, structured summary of the changes made, ensuring the history is readable and meaningful.
  '';
}
