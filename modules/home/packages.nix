{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      libfido2  # 提供 FIDO2 支持的库
      openssh   # 确保使用的是最新的 openssh
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
