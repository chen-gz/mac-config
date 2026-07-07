{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libfido2 # 提供 FIDO2 支持的库
    just
    devenv
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
    zig
    zls
    openssh # 确保使用的是最新的 openssh
    sequoia-sq
    lazyjj
    mdcat
  ];
}
