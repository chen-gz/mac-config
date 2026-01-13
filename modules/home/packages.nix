{ pkgs, ... }:
{
  home.packages = with pkgs; [
    just
    devbox
    just-lsp
    gemini-cli
    pay-respects
    ripgrep
    curl
  ];
}
