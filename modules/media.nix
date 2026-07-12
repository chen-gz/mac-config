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
      "cloudflared"
    ];
  };

  # 安装 Nix 版本的 caddy
  environment.systemPackages = [
    pkgs.caddy
  ];

  # 声明式管理 Caddyfile
  environment.etc."caddy/Caddyfile".text = ''
    # Secure local reverse proxy with separate site blocks on port 80
    http://ra {
    	reverse_proxy 127.0.0.1:7878
    }

    http://so {
    	reverse_proxy 127.0.0.1:8989
    }

    http://pr {
    	reverse_proxy 127.0.0.1:9696
    }

    http://sab {
    	reverse_proxy 127.0.0.1:8080
    }

    http://ba {
    	reverse_proxy 127.0.0.1:6767
    }

    http://jf {
    	reverse_proxy 127.0.0.1:8096
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

  # 使用 launchd 管理 cloudflared 系统级服务
  # Note: The Cloudflare tunnel token must be manually written to /etc/cloudflare-token
  # (e.g., echo "TOKEN" | sudo tee /etc/cloudflare-token)
  launchd.daemons.cloudflared = {
    command = "/bin/sh -c 'exec /opt/homebrew/bin/cloudflared tunnel --no-autoupdate run --token \"$(cat /etc/cloudflare-token 2>/dev/null)\"'";
    serviceConfig = {
      Label = "com.cloudflare.cloudflared";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/cloudflared.out.log";
      StandardErrorPath = "/var/log/cloudflared.err.log";
    };
  };

  # 仅在此电脑上自动配置 /etc/hosts 映射，并修复媒体应用权限/签名
  system.activationScripts.postActivation = {
    enable = true;
    text = ''
      if ! grep -q "127.0.0.1 ra so pr sab ba jf" /etc/hosts; then
        echo "Adding local media stack host mappings to /etc/hosts"
        echo "127.0.0.1 ra so pr sab ba jf" >> /etc/hosts
      fi

      echo "Fixing quarantine and codesign for media applications..."
      for app in Radarr Sonarr Prowlarr SABnzbd Jellyfin; do
        app_path="/Applications/''${app}.app"
        if [ -d "$app_path" ]; then
          # Remove quarantine flag
          xattr -r -d com.apple.quarantine "$app_path" 2>/dev/null || true
          
          # For unsigned applications, apply ad-hoc signatures
          if [ "''${app}" = "Radarr" ] || [ "''${app}" = "Sonarr" ] || [ "''${app}" = "Prowlarr" ]; then
            if ! codesign -v "$app_path" 2>/dev/null; then
              echo "Applying ad-hoc signature to ''${app}..."
              codesign --force --deep --sign - "$app_path" 2>/dev/null || true
            fi
          fi
        fi
      done
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
