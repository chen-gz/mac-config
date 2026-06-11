{ pkgs, ... }:

{
  # 仅在需要此配置的电脑上安装媒体软件
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
        name = "bazarr";
        start_service = true;
        restart_service = "changed";
      }
    ];
  };

  # 安装 Nix 版本的 caddy
  environment.systemPackages = [ pkgs.caddy ];

  # 声明式管理 Caddyfile
  environment.etc."caddy/Caddyfile".text = ''
    # Secure local reverse proxy with separate site blocks on port 80
    http://ra {
    	reverse_proxy guangzongs-mac-mini:7878
    }

    http://so {
    	reverse_proxy guangzongs-mac-mini:8989
    }

    http://pr {
    	reverse_proxy guangzongs-mac-mini:9696
    }

    http://sab {
    	reverse_proxy guangzongs-mac-mini:8080
    }

    http://ba {
    	reverse_proxy guangzongs-mac-mini:6767
    }

    http://jf {
    	reverse_proxy guangzongs-mac-mini:8096
    }
  '';

  # 使用 launchd 管理 caddy 系统级服务
  launchd.daemons.caddy = {
    command = "${pkgs.caddy}/bin/caddy run --config /etc/caddy/Caddyfile";
    serviceConfig = {
      Label = "org.nixos.caddy";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/caddy.out.log";
      StandardErrorPath = "/var/log/caddy.err.log";
    };
  };

  # 仅在此电脑上自动配置 /etc/hosts 映射
  system.activationScripts.postActivation = {
    enable = true;
    text = ''
      if ! grep -q "127.0.0.1 ra so pr sab ba jf" /etc/hosts; then
        echo "Adding local media stack host mappings to /etc/hosts"
        echo "127.0.0.1 ra so pr sab ba jf" >> /etc/hosts
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
