{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      libfido2 # 提供 FIDO2 支持的库
      just
      devbox
      just-lsp
      pay-respects
      ripgrep
      fd
      btop
      yazi
      hexyl
      jql
      duf
      dust
      nerd-fonts.jetbrains-mono
      zellij
      zig
      lmstudio
      telegram-desktop
    ]
    ++ (
      if stdenv.isDarwin then
        [
          openssh # 确保使用的是最新的 openssh
          gemini-cli
        ]
      else
        [
          waybar
        ]
    );
}
