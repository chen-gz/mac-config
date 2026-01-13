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
    ]
    ++ (if stdenv.isDarwin then [ gemini-cli ] else [ ]);
}
