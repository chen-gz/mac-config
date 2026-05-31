{ ... }:

{
  # 仅在需要此配置的电脑上安装媒体软件和 Caddy
  homebrew = {
    casks = [
      "radarr"
      "sonarr"
      "sabnzbd"
      "prowlarr"
      "bazarr"
    ];
    brews = [
      "caddy"
    ];
  };

  # 仅在此电脑上自动配置 /etc/hosts 映射
  system.activationScripts.postActivation = {
    enable = true;
    text = ''
      if ! grep -q "127.0.0.1 ra so pr sab ba" /etc/hosts; then
        echo "Adding local media stack host mappings to /etc/hosts"
        echo "127.0.0.1 ra so pr sab ba" >> /etc/hosts
      fi
    '';
  };
}
