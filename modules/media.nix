{ pkgs, ... }:

{
  # 仅在需要此配置的电脑上安装媒体软件
  homebrew = {
    casks = [
      "steam"
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



  # 使用 launchd 管理 cloudflared 系统级服务
  # Token 由 keys/cloudflare-token.gpg 加密备份，通过 --token-file 从 /etc/cloudflare-token 读取，避免在命令行参数中暴露敏感凭据
  launchd.daemons.cloudflared = {
    command = "/opt/homebrew/bin/cloudflared tunnel --no-autoupdate run --token-file /etc/cloudflare-token";
    serviceConfig = {
      Label = "com.cloudflare.cloudflared";
      KeepAlive = true;
      RunAtLoad = true;
      EnvironmentVariables = {
        TUNNEL_TOKEN_FILE = "/etc/cloudflare-token";
      };
      StandardOutPath = "/var/log/cloudflared.out.log";
      StandardErrorPath = "/var/log/cloudflared.err.log";
    };
  };

  # 仅在此电脑上自动配置 /etc/hosts 映射，并修复媒体应用权限/签名
  system.activationScripts.postActivation = {
    enable = true;
    text = ''
      # 自动从加密 keys/ 恢复 /etc/cloudflare-token
      if [ ! -f /etc/cloudflare-token ] && [ -f /Users/guangzong/.config/nix-darwin/keys/cloudflare-token.gpg ]; then
        token=$(sudo -u guangzong ${pkgs.gnupg}/bin/gpg --quiet -d /Users/guangzong/.config/nix-darwin/keys/cloudflare-token.gpg 2>/dev/null || true)
        if [ -n "$token" ]; then
          echo "Restoring /etc/cloudflare-token from keys/cloudflare-token.gpg..."
          echo "$token" > /etc/cloudflare-token
          chmod 600 /etc/cloudflare-token
        fi
      fi

      # 确保 /etc/cloudflare-token 仅 root 具备读写权限 (0600)
      if [ -f /etc/cloudflare-token ]; then
        chmod 600 /etc/cloudflare-token
      fi

      # 清理旧的本地 Caddy hosts 映射与残留系统服务
      sed -i "" '/127.0.0.1 ra so pr sab ba jf/d' /etc/hosts 2>/dev/null || true
      launchctl bootout system/org.nixos.caddy 2>/dev/null || true
      rm -f /Library/LaunchDaemons/org.nixos.caddy.plist 2>/dev/null || true

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

            # 禁止外部媒体硬盘 (/Volumes/extdisk) 的 Spotlight 索引，避免机械硬盘频繁被系统唤醒
            if [ -d "/Volumes/extdisk" ]; then
              touch /Volumes/extdisk/.metadata_never_index 2>/dev/null || true
              /usr/bin/mdutil -i off /Volumes/extdisk 2>/dev/null || true
            fi

            # 自动配置媒体服务备份目录软链接至 Google Drive（重装系统一键自愈）
            GDRIVE_BACKUP="/Users/guangzong/Google Drive/My Drive/MediaStack-Backups"
            if [ -d "/Users/guangzong/Google Drive/My Drive" ]; then
              mkdir -p "$GDRIVE_BACKUP"/{radarr,sonarr,prowlarr,bazarr,sabnzbd,jellyfin}
              chown -R guangzong "$GDRIVE_BACKUP" 2>/dev/null || true

              link_backup() {
                src="$1"
                target="$2"
                mkdir -p "$(dirname "$src")"
                if [ -d "$src" ] && [ ! -L "$src" ]; then
                  cp -R "$src/"* "$target/" 2>/dev/null || true
                  rm -rf "$src"
                fi
                if [ ! -L "$src" ]; then
                  ln -s "$target" "$src"
                  chown -h guangzong "$src" 2>/dev/null || true
                fi
              }

              link_backup "/Users/guangzong/Library/Application Support/Radarr/Backups" "$GDRIVE_BACKUP/radarr"
              link_backup "/Users/guangzong/.config/Sonarr/Backups" "$GDRIVE_BACKUP/sonarr"
              link_backup "/Users/guangzong/Library/Application Support/Prowlarr/Backups" "$GDRIVE_BACKUP/prowlarr"
              link_backup "/opt/homebrew/var/bazarr/backup" "$GDRIVE_BACKUP/bazarr"
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
    media-backup = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash"
          "/Users/guangzong/.config/nix-darwin/scripts/backup-media.sh"
        ];
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 0;
            Weekday = 0; # 每周日凌晨 3:00 自动触发备份
          }
        ];
        ProcessType = "Background";
        StandardOutPath = "/tmp/media-backup.out.log";
        StandardErrorPath = "/tmp/media-backup.err.log";
      };
    };
  };
}
