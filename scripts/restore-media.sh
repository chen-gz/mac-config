#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Media Stack One-Click Restoration Script
# Automatically restores databases and configs from Google Drive tar.gz archives
# ==============================================================================

export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

GDRIVE_ROOT="${HOME}/Google Drive/My Drive/MediaStack-Backups"
UID_VAL=$(id -u)

if [ ! -d "$GDRIVE_ROOT" ]; then
    echo "Error: Google Drive backup directory not found at '$GDRIVE_ROOT'." >&2
    echo "Please ensure Google Drive is mounted and synced before restoring." >&2
    exit 1
fi

LATEST_ARCHIVE="${GDRIVE_ROOT}/mediastack-backup-latest.tar.gz"
SOURCE_DIR="$GDRIVE_ROOT"

if [ -f "$LATEST_ARCHIVE" ]; then
    echo "Found compressed backup archive: $(basename "$LATEST_ARCHIVE")"
    EXTRACT_DIR=$(mktemp -d "/tmp/mediastack-restore.XXXXXX")
    trap 'rm -rf "$EXTRACT_DIR"' EXIT
    echo "Extracting archive to staging directory..."
    tar -xzf "$LATEST_ARCHIVE" -C "$EXTRACT_DIR"
    SOURCE_DIR="$EXTRACT_DIR"
else
    echo "Notice: Archive not found, checking legacy folder structure in $GDRIVE_ROOT..."
fi

echo "=================================================================="
echo " Starting Media Stack One-Click Database & Config Restore..."
echo "=================================================================="

# --- 1. Radarr ---
echo "===> [1/5] Restoring Radarr..."
launchctl bootout "gui/$UID_VAL/org.nixos.radarr" 2>/dev/null || true
sleep 1
LATEST_RADARR=$(find "$SOURCE_DIR/radarr" -name "*.zip" -type f 2>/dev/null | sort | tail -n 1 || true)
if [ -n "$LATEST_RADARR" ] && [ -f "$LATEST_RADARR" ]; then
    echo "     Found latest backup: $(basename "$LATEST_RADARR")"
    mkdir -p "$HOME/Library/Application Support/Radarr"
    unzip -q -o "$LATEST_RADARR" "radarr.db" "config.xml" -d "$HOME/Library/Application Support/Radarr/" 2>/dev/null || true
    echo "     Radarr database restored successfully."
else
    echo "     No Radarr backup zip found, skipping."
fi
launchctl bootstrap "gui/$UID_VAL" "$HOME/Library/LaunchAgents/org.nixos.radarr.plist" 2>/dev/null || true

# --- 2. Sonarr ---
echo "===> [2/5] Restoring Sonarr..."
launchctl bootout "gui/$UID_VAL/org.nixos.sonarr" 2>/dev/null || true
sleep 1
LATEST_SONARR=$(find "$SOURCE_DIR/sonarr" -name "*.zip" -type f 2>/dev/null | sort | tail -n 1 || true)
if [ -n "$LATEST_SONARR" ] && [ -f "$LATEST_SONARR" ]; then
    echo "     Found latest backup: $(basename "$LATEST_SONARR")"
    mkdir -p "$HOME/.config/Sonarr"
    unzip -q -o "$LATEST_SONARR" "sonarr.db" "config.xml" -d "$HOME/.config/Sonarr/" 2>/dev/null || true
    echo "     Sonarr database restored successfully."
else
    echo "     No Sonarr backup zip found, skipping."
fi
launchctl bootstrap "gui/$UID_VAL" "$HOME/Library/LaunchAgents/org.nixos.sonarr.plist" 2>/dev/null || true

# --- 3. Prowlarr ---
echo "===> [3/5] Restoring Prowlarr..."
launchctl bootout "gui/$UID_VAL/org.nixos.prowlarr" 2>/dev/null || true
sleep 1
LATEST_PROWLARR=$(find "$SOURCE_DIR/prowlarr" -name "*.zip" -type f 2>/dev/null | sort | tail -n 1 || true)
if [ -n "$LATEST_PROWLARR" ] && [ -f "$LATEST_PROWLARR" ]; then
    echo "     Found latest backup: $(basename "$LATEST_PROWLARR")"
    mkdir -p "$HOME/Library/Application Support/Prowlarr"
    unzip -q -o "$LATEST_PROWLARR" "prowlarr.db" "config.xml" -d "$HOME/Library/Application Support/Prowlarr/" 2>/dev/null || true
    echo "     Prowlarr database restored successfully."
else
    echo "     No Prowlarr backup zip found, skipping."
fi
launchctl bootstrap "gui/$UID_VAL" "$HOME/Library/LaunchAgents/org.nixos.prowlarr.plist" 2>/dev/null || true

# --- 4. SABnzbd ---
echo "===> [4/5] Restoring SABnzbd..."
launchctl bootout "gui/$UID_VAL/org.nixos.sabnzbd" 2>/dev/null || true
sleep 1
if [ -f "$SOURCE_DIR/sabnzbd/sabnzbd.ini" ]; then
    mkdir -p "$HOME/Library/Application Support/SABnzbd"
    cp "$SOURCE_DIR/sabnzbd/sabnzbd.ini" "$HOME/Library/Application Support/SABnzbd/sabnzbd.ini"
    echo "     SABnzbd sabnzbd.ini restored successfully."
fi
launchctl bootstrap "gui/$UID_VAL" "$HOME/Library/LaunchAgents/org.nixos.sabnzbd.plist" 2>/dev/null || true

# --- 5. Jellyfin ---
echo "===> [5/5] Restoring Jellyfin..."
killall -TERM jellyfin 2>/dev/null || true
sleep 1
if [ -f "$SOURCE_DIR/jellyfin/jellyfin.db" ]; then
    mkdir -p "$HOME/Library/Application Support/jellyfin/data"
    cp "$SOURCE_DIR/jellyfin/jellyfin.db" "$HOME/Library/Application Support/jellyfin/data/jellyfin.db"
    if [ -d "$SOURCE_DIR/jellyfin/config" ]; then
        mkdir -p "$HOME/Library/Application Support/jellyfin/config"
        cp -R "$SOURCE_DIR/jellyfin/config/"* "$HOME/Library/Application Support/jellyfin/config/" 2>/dev/null || true
    fi
    echo "     Jellyfin database and configs restored successfully."
fi

echo "=================================================================="
echo " All Media Stack services and databases have been restored!"
echo "=================================================================="
