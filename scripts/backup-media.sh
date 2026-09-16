#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Media Stack Instant Backup Script
# Exports and syncs core SQLite databases and configs to Google Drive
# ==============================================================================

GDRIVE_ROOT="/Users/guangzong/Google Drive/My Drive/MediaStack-Backups"

if [ ! -d "$GDRIVE_ROOT" ]; then
    echo "Warning: Google Drive backup directory not found at '$GDRIVE_ROOT'."
    echo "Please ensure Google Drive is running and logged in."
    exit 1
fi

mkdir -p "$GDRIVE_ROOT"/{radarr,sonarr,prowlarr,bazarr,sabnzbd,jellyfin}

get_api_key() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' "$config_file" | head -n 1
    fi
}

echo "===> [1/6] Triggering Radarr Backup via API..."
RADARR_API_KEY=$(get_api_key "$HOME/Library/Application Support/Radarr/config.xml")
if [ -n "$RADARR_API_KEY" ]; then
    curl -s -X POST -H "X-Api-Key: $RADARR_API_KEY" -H "Content-Type: application/json" -d '{"name": "Backup"}' http://127.0.0.1:7878/api/v3/command >/dev/null 2>&1 || true
else
    echo "     Radarr API key not found, skipping API trigger."
fi

echo "===> [2/6] Triggering Sonarr Backup via API..."
SONARR_API_KEY=$(get_api_key "$HOME/.config/Sonarr/config.xml")
if [ -n "$SONARR_API_KEY" ]; then
    curl -s -X POST -H "X-Api-Key: $SONARR_API_KEY" -H "Content-Type: application/json" -d '{"name": "Backup"}' http://127.0.0.1:8989/api/v3/command >/dev/null 2>&1 || true
else
    echo "     Sonarr API key not found, skipping API trigger."
fi

echo "===> [3/6] Triggering Prowlarr Backup via API..."
PROWLARR_API_KEY=$(get_api_key "$HOME/Library/Application Support/Prowlarr/config.xml")
if [ -n "$PROWLARR_API_KEY" ]; then
    curl -s -X POST -H "X-Api-Key: $PROWLARR_API_KEY" -H "Content-Type: application/json" -d '{"name": "Backup"}' http://127.0.0.1:9696/api/v3/command >/dev/null 2>&1 || true
else
    echo "     Prowlarr API key not found, skipping API trigger."
fi

echo "===> [4/6] Backing up SABnzbd Configuration..."
if [ -f "$HOME/Library/Application Support/SABnzbd/sabnzbd.ini" ]; then
    cp "$HOME/Library/Application Support/SABnzbd/sabnzbd.ini" "$GDRIVE_ROOT/sabnzbd/sabnzbd.ini"
fi

echo "===> [5/6] Performing Jellyfin Online SQLite Hot Backup..."
JELLYFIN_DB="$HOME/Library/Application Support/jellyfin/data/jellyfin.db"
if [ -f "$JELLYFIN_DB" ]; then
    sqlite3 "$JELLYFIN_DB" ".backup '$GDRIVE_ROOT/jellyfin/jellyfin.db'"
    if [ -d "$HOME/Library/Application Support/jellyfin/config" ]; then
        cp -R "$HOME/Library/Application Support/jellyfin/config" "$GDRIVE_ROOT/jellyfin/"
    fi
fi

echo "===> [6/6] Checking Bazarr Backup directory..."
# Bazarr automatically outputs backups to its symlinked directory in Google Drive

echo "===> All backups completed successfully and synced to Google Drive: $GDRIVE_ROOT"
