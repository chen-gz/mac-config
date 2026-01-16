{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      just
      devbox
      just-lsp
      pay-respects
      ripgrep
      fd
      btop
      yazi
      tealdeer
      nerd-fonts.jetbrains-mono
    ]
    ++ (if stdenv.isDarwin then [ gemini-cli ] else [ ]);
}
