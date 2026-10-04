#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Media Stack Unified Archive Backup Script
# Packages databases and configs into a compressed archive (.tar.gz)
# synced directly to Google Drive with timestamp (mirroring GitHub backup format).
# ==============================================================================

export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

GDRIVE_ROOT="${HOME}/Google Drive/My Drive/MediaStack-Backups"

if [ ! -d "${HOME}/Google Drive/My Drive" ]; then
    echo "Warning: Google Drive not found at '${HOME}/Google Drive/My Drive'." >&2
    echo "Please ensure Google Drive is running and logged in." >&2
    exit 1
fi

mkdir -p "$GDRIVE_ROOT"

STAGING_DIR=$(mktemp -d "/tmp/mediastack-backup.XXXXXX")
trap 'rm -rf "$STAGING_DIR"' EXIT

mkdir -p "$STAGING_DIR"/{radarr,sonarr,prowlarr,sabnzbd,jellyfin}

get_api_key() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' "$config_file" | head -n 1
    fi
}

echo "=================================================================="
echo "          Media Stack Unified Archive Backup Starting"
echo "          Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================================="

HAS_WARNINGS=0

find_latest_zip() {
    local search_path="$1"
    if [ -d "$search_path" ]; then
        find -L "$search_path" -name "*.zip" -type f -print0 2>/dev/null \
            | xargs -0 stat -f "%m %N" 2>/dev/null \
            | sort -nr \
            | head -n 1 \
            | cut -d ' ' -f 2- || true
    fi
}

# --- 1. Radarr ---
echo "===> [1/5] Triggering Radarr Backup via API..."
RADARR_API_KEY=$(get_api_key "$HOME/Library/Application Support/Radarr/config.xml")
if [ -n "$RADARR_API_KEY" ]; then
    curl -s -X POST -H "X-Api-Key: $RADARR_API_KEY" -H "Content-Type: application/json" -d '{"name": "Backup"}' http://127.0.0.1:7878/api/v3/command >/dev/null 2>&1 || true
    sleep 3
fi
LATEST_RADARR=$(find_latest_zip "$HOME/Library/Application Support/Radarr")
if [ -z "$LATEST_RADARR" ] && [ -d "$GDRIVE_ROOT/radarr" ]; then
    LATEST_RADARR=$(find_latest_zip "$GDRIVE_ROOT/radarr")
fi
if [ -n "$LATEST_RADARR" ] && [ -f "$LATEST_RADARR" ]; then
    cp "$LATEST_RADARR" "$STAGING_DIR/radarr/"
    echo "     Radarr backup included: $(basename "$LATEST_RADARR")"
else
    echo "     Warning: No Radarr backup zip found." >&2
    HAS_WARNINGS=1
fi

# --- 2. Sonarr ---
echo "===> [2/5] Triggering Sonarr Backup via API..."
SONARR_API_KEY=$(get_api_key "$HOME/.config/Sonarr/config.xml")
if [ -n "$SONARR_API_KEY" ]; then
    curl -s -X POST -H "X-Api-Key: $SONARR_API_KEY" -H "Content-Type: application/json" -d '{"name": "Backup"}' http://127.0.0.1:8989/api/v3/command >/dev/null 2>&1 || true
    sleep 3
fi
LATEST_SONARR=$(find_latest_zip "$HOME/.config/Sonarr")
if [ -z "$LATEST_SONARR" ] && [ -d "$GDRIVE_ROOT/sonarr" ]; then
    LATEST_SONARR=$(find_latest_zip "$GDRIVE_ROOT/sonarr")
fi
if [ -n "$LATEST_SONARR" ] && [ -f "$LATEST_SONARR" ]; then
    cp "$LATEST_SONARR" "$STAGING_DIR/sonarr/"
    echo "     Sonarr backup included: $(basename "$LATEST_SONARR")"
else
    echo "     Warning: No Sonarr backup zip found." >&2
    HAS_WARNINGS=1
fi

# --- 3. Prowlarr ---
echo "===> [3/5] Triggering Prowlarr Backup via API..."
PROWLARR_API_KEY=$(get_api_key "$HOME/Library/Application Support/Prowlarr/config.xml")
if [ -n "$PROWLARR_API_KEY" ]; then
    curl -s -X POST -H "X-Api-Key: $PROWLARR_API_KEY" -H "Content-Type: application/json" -d '{"name": "Backup"}' http://127.0.0.1:9696/api/v1/command >/dev/null 2>&1 || true
    sleep 3
fi
LATEST_PROWLARR=$(find_latest_zip "$HOME/Library/Application Support/Prowlarr")
if [ -z "$LATEST_PROWLARR" ] && [ -d "$GDRIVE_ROOT/prowlarr" ]; then
    LATEST_PROWLARR=$(find_latest_zip "$GDRIVE_ROOT/prowlarr")
fi
if [ -n "$LATEST_PROWLARR" ] && [ -f "$LATEST_PROWLARR" ]; then
    cp "$LATEST_PROWLARR" "$STAGING_DIR/prowlarr/"
    echo "     Prowlarr backup included: $(basename "$LATEST_PROWLARR")"
else
    echo "     Warning: No Prowlarr backup zip found." >&2
    HAS_WARNINGS=1
fi

# --- 4. SABnzbd ---
echo "===> [4/5] Backing up SABnzbd Configuration..."
if [ -f "$HOME/Library/Application Support/SABnzbd/sabnzbd.ini" ]; then
    cp "$HOME/Library/Application Support/SABnzbd/sabnzbd.ini" "$STAGING_DIR/sabnzbd/sabnzbd.ini"
    echo "     SABnzbd sabnzbd.ini included."
else
    echo "     Warning: SABnzbd configuration not found." >&2
    HAS_WARNINGS=1
fi

# --- 5. Jellyfin ---
echo "===> [5/5] Performing Jellyfin Online SQLite Hot Backup..."
JELLYFIN_DB="$HOME/Library/Application Support/jellyfin/data/jellyfin.db"
if [ -f "$JELLYFIN_DB" ]; then
    if sqlite3 "$JELLYFIN_DB" ".backup '$STAGING_DIR/jellyfin/jellyfin.db'" 2>/dev/null; then
        echo "     Jellyfin database hot backup included."
    else
        echo "     Warning: Failed to hot backup Jellyfin database." >&2
        HAS_WARNINGS=1
    fi
    if [ -d "$HOME/Library/Application Support/jellyfin/config" ]; then
        cp -R "$HOME/Library/Application Support/jellyfin/config" "$STAGING_DIR/jellyfin/" 2>/dev/null || true
    fi
else
    echo "     Warning: Jellyfin database not found at '$JELLYFIN_DB'." >&2
    HAS_WARNINGS=1
fi

# --- 6. 生成元数据报告 ---
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
STATUS="success"
if [ "$HAS_WARNINGS" -eq 1 ]; then
    STATUS="completed_with_warnings"
fi

cat <<EOF > "$STAGING_DIR/latest_backup.json"
{
  "timestamp": "${END_TIME}",
  "status": "${STATUS}",
  "components": {
    "radarr": $([ -n "$LATEST_RADARR" ] && echo '"included"' || echo '"missing"'),
    "sonarr": $([ -n "$LATEST_SONARR" ] && echo '"included"' || echo '"missing"'),
    "prowlarr": $([ -n "$LATEST_PROWLARR" ] && echo '"included"' || echo '"missing"'),
    "sabnzbd": $([ -f "$STAGING_DIR/sabnzbd/sabnzbd.ini" ] && echo '"included"' || echo '"missing"'),
    "jellyfin": $([ -f "$STAGING_DIR/jellyfin/jellyfin.db" ] && echo '"included"' || echo '"missing"')
  }
}
EOF

# --- 7. 打包压缩并原子同步至 Google Drive ---
echo ""
echo "===> Compressing and Syncing Archive to Google Drive..."
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="mediastack-backup-${TIMESTAMP}.tar.gz"
TEMP_ARCHIVE="/tmp/${ARCHIVE_NAME}"

echo "     Creating compressed archive: ${ARCHIVE_NAME}..."
tar -czf "${TEMP_ARCHIVE}" -C "$STAGING_DIR" radarr sonarr prowlarr sabnzbd jellyfin latest_backup.json

echo "     Moving archive to Google Drive: ${GDRIVE_ROOT}..."
mv "${TEMP_ARCHIVE}" "${GDRIVE_ROOT}/${ARCHIVE_NAME}"
cp "${GDRIVE_ROOT}/${ARCHIVE_NAME}" "${GDRIVE_ROOT}/mediastack-backup-latest.tar.gz"
cp "$STAGING_DIR/latest_backup.json" "${GDRIVE_ROOT}/latest_backup.json"

# 保留最近 30 份历史时间戳压缩包，自动清理旧归档防止占用过多云盘空间
RETENTION_COUNT=30
ls -1t "${GDRIVE_ROOT}"/mediastack-backup-*.tar.gz 2>/dev/null | grep -v 'mediastack-backup-latest.tar.gz' | tail -n +"$((RETENTION_COUNT + 1))" | xargs rm -f 2>/dev/null || true

ARCHIVE_SIZE=$(ls -lh "${GDRIVE_ROOT}/${ARCHIVE_NAME}" | awk '{print $5}')

echo "=================================================================="
echo "          Media Stack Backup Complete"
echo "          Finished   : ${END_TIME}"
echo "          Archive    : ${GDRIVE_ROOT}/${ARCHIVE_NAME} (${ARCHIVE_SIZE})"
echo "          Latest     : ${GDRIVE_ROOT}/mediastack-backup-latest.tar.gz"
echo "          Status     : ${STATUS}"
echo "=================================================================="
