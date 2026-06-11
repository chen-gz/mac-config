{ ... }:

{
  # 仅在需要此配置的电脑上安装媒体软件和 Caddy
  homebrew = {
    casks = [
      "radarr"
      "sonarr"
      "jellyfin"
      "sabnzbd"
      "prowlarr"
    ];
    brews = [
      {
        name = "caddy";
        start_service = true;
        restart_service = "changed";
      }
      {
        name = "bazarr";
        start_service = true;
        restart_service = "changed";
      }
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

  # 配置 launchd 用户代理，实现开机自启（登录时启动）
  launchd.user.agents = {
    radarr = {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Radarr.app/Contents/MacOS/Radarr"
          "-nobrowser"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "/tmp/radarr.out.log";
        StandardErrorPath = "/tmp/radarr.err.log";
      };
    };
    sonarr = {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Sonarr.app/Contents/MacOS/Sonarr"
          "-nobrowser"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "/tmp/sonarr.out.log";
        StandardErrorPath = "/tmp/sonarr.err.log";
      };
    };
    prowlarr = {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Prowlarr.app/Contents/MacOS/Prowlarr"
          "-nobrowser"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "/tmp/prowlarr.out.log";
        StandardErrorPath = "/tmp/prowlarr.err.log";
      };
    };
    sabnzbd = {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/SABnzbd.app/Contents/MacOS/SABnzbd"
          "--browser"
          "0"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "/tmp/sabnzbd.out.log";
        StandardErrorPath = "/tmp/sabnzbd.err.log";
      };
    };
  };
}
