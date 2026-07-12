{ pkgs, ... }:
{
  # Sequoia-PGP 替代方案说明：
  # 我们安装了 sequoia-chameleon-gnupg 以提供 gpg 接口的 Rust 实现。
  # Git 已配置为使用 gpg-sq 进行签名。
  # 对于 SSH Agent，由于 Sequoia 尚未提供成熟的独立 Agent，我们继续沿用 GnuPG 的 gpg-agent 作为后端。
  
  programs.gpg = {
    enable = true;
    package = pkgs.sequoia-chameleon-gnupg;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
    };
  };

  home.packages = [
    # GnuPG agent tools (gpg-agent, gpg-connect-agent, etc.) to support sequoia-chameleon-gnupg
    (pkgs.runCommand "gnupg-agent-tools" { } ''
      mkdir -p $out/bin
      for f in gpg-agent gpg-connect-agent gpg-preset-passphrase gpg-card dirmngr; do
        if [ -e "${pkgs.gnupg}/bin/$f" ]; then
          ln -s "${pkgs.gnupg}/bin/$f" $out/bin/$f
        fi
      done
    '')
  ];

  home.file = {
    ".gnupg/gpg-agent.conf".text = ''
      enable-ssh-support
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
      default-cache-ttl 259200
      max-cache-ttl 259200
      default-cache-ttl-ssh 259200
      max-cache-ttl-ssh 259200
      allow-loopback-pinentry
      allow-preset-passphrase
      no-grab
    '';
    ".gnupg/scdaemon.conf".text = ''
      # Use macOS native smartcard services
      disable-ccid
    '';
  };
}
