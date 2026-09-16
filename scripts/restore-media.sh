#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Media Stack One-Click Restoration Script
# Automatically restores databases and configs from Google Drive backups
# ==============================================================================

GDRIVE_ROOT="${HOME}/Google Drive/My Drive/MediaStack-Backups"
UID_VAL=$(id -u)

if [ ! -d "$GDRIVE_ROOT" ]; then
    echo "Error: Google Drive backup directory not found at '$GDRIVE_ROOT'."
    echo "Please ensure Google Drive is mounted and synced before restoring."
    exit 1
fi

echo "=================================================================="
echo " Starting Media Stack One-Click Database & Config Restore..."
echo "=================================================================="

# --- 1. Radarr ---
echo "===> [1/6] Restoring Radarr..."
launchctl bootout "gui/$UID_VAL/org.nixos.radarr" 2>/dev/null || true
sleep 1
LATEST_RADARR=$(find "$GDRIVE_ROOT/radarr" -name "*.zip" -type f | sort | tail -n 1)
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
echo "===> [2/6] Restoring Sonarr..."
launchctl bootout "gui/$UID_VAL/org.nixos.sonarr" 2>/dev/null || true
sleep 1
LATEST_SONARR=$(find "$GDRIVE_ROOT/sonarr" -name "*.zip" -type f | sort | tail -n 1)
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
echo "===> [3/6] Restoring Prowlarr..."
launchctl bootout "gui/$UID_VAL/org.nixos.prowlarr" 2>/dev/null || true
sleep 1
LATEST_PROWLARR=$(find "$GDRIVE_ROOT/prowlarr" -name "*.zip" -type f | sort | tail -n 1)
if [ -n "$LATEST_PROWLARR" ] && [ -f "$LATEST_PROWLARR" ]; then
    echo "     Found latest backup: $(basename "$LATEST_PROWLARR")"
    mkdir -p "$HOME/Library/Application Support/Prowlarr"
    unzip -q -o "$LATEST_PROWLARR" "prowlarr.db" "config.xml" -d "$HOME/Library/Application Support/Prowlarr/" 2>/dev/null || true
    echo "     Prowlarr database restored successfully."
else
    echo "     No Prowlarr backup zip found, skipping."
fi
launchctl bootstrap "gui/$UID_VAL" "$HOME/Library/LaunchAgents/org.nixos.prowlarr.plist" 2>/dev/null || true

# --- 4. Bazarr ---
echo "===> [4/6] Restoring Bazarr..."
brew services stop bazarr 2>/dev/null || true
sleep 1
LATEST_BAZARR=$(find "$GDRIVE_ROOT/bazarr" -name "*.zip" -type f | sort | tail -n 1)
if [ -n "$LATEST_BAZARR" ] && [ -f "$LATEST_BAZARR" ]; then
    echo "     Found latest backup: $(basename "$LATEST_BAZARR")"
    mkdir -p "/opt/homebrew/var/bazarr"
    unzip -q -o "$LATEST_BAZARR" "bazarr.db" "config/config.yaml" -d "/opt/homebrew/var/bazarr/" 2>/dev/null || true
    echo "     Bazarr database restored successfully."
else
    echo "     No Bazarr backup zip found, skipping."
fi
brew services start bazarr 2>/dev/null || true

# --- 5. SABnzbd ---
echo "===> [5/6] Restoring SABnzbd..."
launchctl bootout "gui/$UID_VAL/org.nixos.sabnzbd" 2>/dev/null || true
sleep 1
if [ -f "$GDRIVE_ROOT/sabnzbd/sabnzbd.ini" ]; then
    mkdir -p "$HOME/Library/Application Support/SABnzbd"
    cp "$GDRIVE_ROOT/sabnzbd/sabnzbd.ini" "$HOME/Library/Application Support/SABnzbd/sabnzbd.ini"
    echo "     SABnzbd sabnzbd.ini restored successfully."
fi
launchctl bootstrap "gui/$UID_VAL" "$HOME/Library/LaunchAgents/org.nixos.sabnzbd.plist" 2>/dev/null || true

# --- 6. Jellyfin ---
echo "===> [6/6] Restoring Jellyfin..."
killall -TERM jellyfin 2>/dev/null || true
sleep 1
if [ -f "$GDRIVE_ROOT/jellyfin/jellyfin.db" ]; then
    mkdir -p "$HOME/Library/Application Support/jellyfin/data"
    cp "$GDRIVE_ROOT/jellyfin/jellyfin.db" "$HOME/Library/Application Support/jellyfin/data/jellyfin.db"
    if [ -d "$GDRIVE_ROOT/jellyfin/config" ]; then
        mkdir -p "$HOME/Library/Application Support/jellyfin/config"
        cp -R "$GDRIVE_ROOT/jellyfin/config/"* "$HOME/Library/Application Support/jellyfin/config/" 2>/dev/null || true
    fi
    echo "     Jellyfin database and configs restored successfully."
fi

echo "=================================================================="
echo " All Media Stack services and databases have been restored!"
echo "=================================================================="
