{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fish
    git
    curl
    bat
    helix
    ripgrep
    fzf
    lazygit
    delta
    just
    devbox
    just-lsp
    gemini-cli
  ];
}
