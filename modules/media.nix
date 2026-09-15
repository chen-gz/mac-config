{ pkgs, ... }:

{
  # 仅在需要此配置的电脑上安装媒体软件
  homebrew = {
    casks = [
      "steam"
      "radarr"
      "sonarr"
      "lidarr"
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
      {
        name = "forgejo";
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

    http://li {
    	reverse_proxy 127.0.0.1:8686
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

    http://git {
    	reverse_proxy 127.0.0.1:3000
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
      if ! grep -q "127.0.0.1 ra so pr sab ba jf li git" /etc/hosts; then
        echo "Adding local media and git stack host mappings to /etc/hosts"
        sed -i "" '/127.0.0.1 ra so pr sab ba jf/d' /etc/hosts 2>/dev/null || true
        echo "127.0.0.1 ra so pr sab ba jf li git" >> /etc/hosts
      fi

      # 确保 Forgejo 配置目录就绪并提供初始配置模版
      mkdir -p /opt/homebrew/var/forgejo/custom/conf
      chown -R guangzong /opt/homebrew/var/forgejo 2>/dev/null || true
      if [ ! -f /opt/homebrew/var/forgejo/custom/conf/app.ini ]; then
        echo "Initializing Forgejo configuration template..."
        cat << 'EOF' > /opt/homebrew/var/forgejo/custom/conf/app.ini
APP_NAME = Forgejo: Git Backup & Mirror
RUN_USER = guangzong
RUN_MODE = prod
WORK_PATH = /opt/homebrew/var/forgejo

[repository]
ROOT = /opt/homebrew/var/forgejo/data/forgejo-repositories

[database]
DB_TYPE = sqlite3
PATH = /opt/homebrew/var/forgejo/data/forgejo.db

[server]
APP_DATA_PATH = /opt/homebrew/var/forgejo/data
DOMAIN = git
SSH_DOMAIN = localhost
HTTP_PORT = 3000
ROOT_URL = http://git/
DISABLE_SSH = false
START_SSH_SERVER = true
SSH_PORT = 2222
SSH_LISTEN_PORT = 2222
BUILTIN_SSH_SERVER_KEY_TYPE = ed25519
LFS_START_SERVER = true

[mirror]
ENABLED = true
DEFAULT_INTERVAL = 8h
MIN_INTERVAL = 10m

[security]
INSTALL_LOCK = false
EOF
        chown guangzong /opt/homebrew/var/forgejo/custom/conf/app.ini 2>/dev/null || true
      fi

      echo "Fixing quarantine and codesign for media applications..."
      for app in Radarr Sonarr Prowlarr SABnzbd Jellyfin Lidarr; do
        app_path="/Applications/''${app}.app"
        if [ -d "$app_path" ]; then
          # Remove quarantine flag
          xattr -r -d com.apple.quarantine "$app_path" 2>/dev/null || true
          
          # For unsigned applications, apply ad-hoc signatures
          if [ "''${app}" = "Radarr" ] || [ "''${app}" = "Sonarr" ] || [ "''${app}" = "Prowlarr" ] || [ "''${app}" = "Lidarr" ]; then
            if ! codesign -v "$app_path" 2>/dev/null; then
              echo "Applying ad-hoc signature to ''${app}..."
              codesign --force --deep --sign - "$app_path" 2>/dev/null || true
            fi
          fi
        fi
      done

      # 禁止外部媒体硬盘 (/Volumes/extdisk) 的 Spotlight 索引，避免机械硬盘频繁被系统唤醒
      if [ -d "/Volumes/extdisk" ]; then
        touch /Volumes/extdisk/.metadata_never_index 2>/dev/null || true
        /usr/bin/mdutil -i off /Volumes/extdisk 2>/dev/null || true
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
    lidarr = {
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Lidarr.app/Contents/MacOS/Lidarr"
          "-nobrowser"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "/tmp/lidarr.out.log";
        StandardErrorPath = "/tmp/lidarr.err.log";
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
