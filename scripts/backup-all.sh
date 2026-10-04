#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Unified One-Click Full Backup (Media Stack + GitHub)
# Synchronously executes all backup pipelines to Google Drive archives
# ==============================================================================

export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo "=================================================================="
echo "          🚀 Starting Full System Backup (Media + GitHub)"
echo "          Start Time: ${START_TIME}"
echo "=================================================================="
echo ""

MEDIA_STATUS=0
GITHUB_STATUS=0

# 1. 执行媒体栈备份
echo "------------------------------------------------------------------"
echo " [Step 1/2] Media Stack Backup (Radarr, Sonarr, Jellyfin, etc.)"
echo "------------------------------------------------------------------"
if "${SCRIPT_DIR}/backup-media.sh"; then
    echo "✅ Media Stack Backup finished successfully."
else
    echo "⚠️ Media Stack Backup finished with warnings or errors."
    MEDIA_STATUS=1
fi

echo ""

# 2. 执行 GitHub 代码镜像备份
echo "------------------------------------------------------------------"
echo " [Step 2/2] GitHub Full Mirror Backup (Repos & Gists)"
echo "------------------------------------------------------------------"
if "${SCRIPT_DIR}/backup-github.sh"; then
    echo "✅ GitHub Mirror Backup finished successfully."
else
    echo "⚠️ GitHub Mirror Backup finished with warnings or errors."
    GITHUB_STATUS=1
fi

echo ""
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo "=================================================================="
echo "          🎉 Full Backup Pipeline Completed"
echo "          Finished Time : ${END_TIME}"
echo "          Media Backup  : $([ $MEDIA_STATUS -eq 0 ] && echo '✅ SUCCESS' || echo '⚠️ WARNING/FAILED')"
echo "          GitHub Backup : $([ $GITHUB_STATUS -eq 0 ] && echo '✅ SUCCESS' || echo '⚠️ WARNING/FAILED')"
echo "=================================================================="

if [ $MEDIA_STATUS -ne 0 ] || [ $GITHUB_STATUS -ne 0 ]; then
    exit 1
fi
