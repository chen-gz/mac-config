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
    ]
    ++ (if stdenv.isDarwin then [ gemini-cli ] else [ ]);
}
