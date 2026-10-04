{
  pkgs,
  username ? "guangzong",
  ...
}:

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
      if [ ! -f /etc/cloudflare-token ] && [ -f /Users/${username}/.config/nix-darwin/keys/cloudflare-token.gpg ]; then
        token=$(sudo -u ${username} ${pkgs.gnupg}/bin/gpg --quiet -d /Users/${username}/.config/nix-darwin/keys/cloudflare-token.gpg 2>/dev/null || true)
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
            if /sbin/mount | grep -q '/Volumes/extdisk'; then
              if [ ! -f "/Volumes/extdisk/.metadata_never_index" ]; then
                touch /Volumes/extdisk/.metadata_never_index 2>/dev/null || true
              fi
              /usr/bin/mdutil -i off /Volumes/extdisk >/dev/null 2>&1 || true
            fi

            # 外部媒体硬盘 (/Volumes/extdisk) nobrowse 挂载固化，阻断 Finder 与 CacheDelete (deleted) 唤醒
            EXTDISK_UUID="3DF1A047-9D24-3B78-82CB-420E76C3C671"
            if [ -f /etc/fstab ]; then
              sed -i "" 's|/Volumes/extdisk|none|g' /etc/fstab 2>/dev/null || true
              if ! grep -q "$EXTDISK_UUID" /etc/fstab; then
                echo "Adding nobrowse mount entry for extdisk to /etc/fstab..."
                echo "UUID=$EXTDISK_UUID none hfs rw,auto,nobrowse 0 0" >> /etc/fstab
              fi
            else
              echo "UUID=$EXTDISK_UUID none hfs rw,auto,nobrowse 0 0" > /etc/fstab
            fi

            if /sbin/mount | grep '/Volumes/extdisk' | grep -qv 'nobrowse'; then
              mount -u -o nobrowse /Volumes/extdisk 2>/dev/null || true
              chflags hidden /Volumes/extdisk 2>/dev/null || true
            fi

            # 自动配置媒体服务与 GitHub 备份归档目录至 Google Drive（重装系统一键自愈）
            GDRIVE_BACKUP="/Users/${username}/Google Drive/My Drive/MediaStack-Backups"
            GDRIVE_GH_BACKUP="/Users/${username}/Google Drive/My Drive/GitHub-Backups"
            if [ -d "/Users/${username}/Google Drive/My Drive" ]; then
              mkdir -p "$GDRIVE_BACKUP"
              mkdir -p "$GDRIVE_GH_BACKUP"
              chown -R ${username} "$GDRIVE_BACKUP" 2>/dev/null || true
              chown -R ${username} "$GDRIVE_GH_BACKUP" 2>/dev/null || true

              # 解除 Radarr/Sonarr/Prowlarr 历史软链接，改由 backup-media 统一打包上传
              for app in Radarr Prowlarr; do
                p="/Users/${username}/Library/Application Support/$app/Backups"
                if [ -L "$p" ]; then
                  rm -f "$p"
                  mkdir -p "$p"
                  chown ${username} "$p" 2>/dev/null || true
                fi
              done
              p="/Users/${username}/.config/Sonarr/Backups"
              if [ -L "$p" ]; then
                rm -f "$p"
                mkdir -p "$p"
                chown ${username} "$p" 2>/dev/null || true
              fi
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
          "/Users/${username}/.config/nix-darwin/scripts/backup-media.sh"
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
    github-backup = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash"
          "/Users/${username}/.config/nix-darwin/scripts/backup-github.sh"
        ];
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 5;
            Weekday = 0; # 每周日凌晨 3:05 自动触发备份（紧随 3:00 媒体备份，同一活跃周期）
          }
        ];
        ProcessType = "Background";
        StandardOutPath = "/tmp/github-backup.out.log";
        StandardErrorPath = "/tmp/github-backup.err.log";
      };
    };
  };
}
