#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# GitHub Automated Mirror Backup Script
# Mirrors all user repositories (public & private) and gists to external storage
# ==============================================================================

export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:${HOME}/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BACKUP_ROOT="${BACKUP_ROOT:-/Volumes/extdisk/Backups/github}"

echo "=================================================================="
echo "          GitHub Automated Mirror Backup Starting"
echo "          Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================================="

# 1. 验证目标外部卷挂载状态
if [ ! -d "/Volumes/extdisk" ]; then
    echo "Error: /Volumes/extdisk is not mounted." >&2
    echo "Aborting backup to prevent writing to system storage." >&2
    exit 1
fi

# 创建备份根目录与子目录
mkdir -p "${BACKUP_ROOT}/repos" "${BACKUP_ROOT}/gists"

if [ ! -w "${BACKUP_ROOT}" ]; then
    echo "Error: ${BACKUP_ROOT} is not writable by $(whoami)." >&2
    echo "Please ensure correct directory permissions on /Volumes/extdisk/Backups." >&2
    exit 1
fi

# 2. 获取并解密 GitHub Token
find_github_token() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo "$GITHUB_TOKEN"
        return
    fi

    local candidates=(
        "${REPO_ROOT}/keys/github-token.gpg"
        "${REPO_ROOT}/keys/github-token.asc"
        "${HOME}/.config/nix-darwin/keys/github-token.gpg"
        "${HOME}/.config/nix-darwin/keys/github-token.asc"
    )

    for key_file in "${candidates[@]}"; do
        if [ -f "$key_file" ]; then
            local decrypted
            decrypted=$(gpg --quiet -d "$key_file" 2>/dev/null || true)
            if [ -n "$decrypted" ]; then
                echo "$decrypted"
                return
            fi
        fi
    done
}

TOKEN=$(find_github_token)
if [ -z "$TOKEN" ]; then
    echo "Error: Could not decrypt or locate GitHub API token." >&2
    exit 1
fi

# 构造认证头信息（Basic Auth 避免在本地 git config 中暴露明文 token）
B64_AUTH=$(printf "%s" "x-access-token:${TOKEN}" | base64 | tr -d '\r\n')
GIT_AUTH_HEADER="Authorization: Basic ${B64_AUTH}"
API_AUTH_HEADER="Authorization: token ${TOKEN}"

# 3. 验证 GitHub 用户信息
USER_JSON=$(curl -sf -H "$API_AUTH_HEADER" "https://api.github.com/user" 2>/dev/null || true)
if [ -z "$USER_JSON" ]; then
    echo "Error: Failed to authenticate with GitHub API." >&2
    exit 1
fi

GH_USER=$(echo "$USER_JSON" | jq -r '.login')
TOTAL_PRIVATE_REPOS=$(echo "$USER_JSON" | jq -r '.total_private_repos // 0')
PUBLIC_REPOS=$(echo "$USER_JSON" | jq -r '.public_repos // 0')

echo "===> Authenticated as: ${GH_USER}"
echo "     Account stats: ${PUBLIC_REPOS} public repos, ${TOTAL_PRIVATE_REPOS} private repos"
echo "     Destination: ${BACKUP_ROOT}"
echo ""

# 4. 备份代码仓库 (Git Mirror 镜像)
echo "===> [1/2] Backing up Repositories for ${GH_USER}..."
PAGE=1
TOTAL_REPOS_SYNCED=0
FAILED_REPOS_COUNT=0
declare -a FAILED_REPOS=()

while true; do
    PAGE_JSON=$(curl -sf -H "$API_AUTH_HEADER" "https://api.github.com/user/repos?affiliation=owner&per_page=100&page=${PAGE}" 2>/dev/null || true)
    ITEMS_COUNT=$(echo "$PAGE_JSON" | jq '. | length' 2>/dev/null || echo 0)

    if [ "$ITEMS_COUNT" -eq 0 ]; then
        break
    fi

    for i in $(seq 0 $((ITEMS_COUNT - 1))); do
        REPO_NAME=$(echo "$PAGE_JSON" | jq -r ".[$i].name")
        REPO_FULL=$(echo "$PAGE_JSON" | jq -r ".[$i].full_name")
        REPO_PRIVATE=$(echo "$PAGE_JSON" | jq -r ".[$i].private")
        CLONE_URL="https://github.com/${REPO_FULL}.git"
        TARGET_DIR="${BACKUP_ROOT}/repos/${REPO_NAME}.git"

        TOTAL_REPOS_SYNCED=$((TOTAL_REPOS_SYNCED + 1))
        printf "  -> [%02d] %-30s (private: %-5s)... " "$TOTAL_REPOS_SYNCED" "$REPO_NAME" "$REPO_PRIVATE"

        if [ ! -d "$TARGET_DIR" ]; then
            if git -c http.extraHeader="$GIT_AUTH_HEADER" clone --mirror "$CLONE_URL" "$TARGET_DIR" >/dev/null 2>&1; then
                echo "[CLONED]"
            else
                echo "[FAILED CLONE]"
                FAILED_REPOS_COUNT=$((FAILED_REPOS_COUNT + 1))
                FAILED_REPOS+=("$REPO_FULL")
            fi
        else
            if git -C "$TARGET_DIR" -c http.extraHeader="$GIT_AUTH_HEADER" remote update --prune >/dev/null 2>&1; then
                echo "[UPDATED]"
            else
                echo "[FAILED UPDATE]"
                FAILED_REPOS_COUNT=$((FAILED_REPOS_COUNT + 1))
                FAILED_REPOS+=("$REPO_FULL")
            fi
        fi
    done

    PAGE=$((PAGE + 1))
done

echo ""

# 5. 备份 Gists
echo "===> [2/2] Backing up Gists for ${GH_USER}..."
PAGE=1
TOTAL_GISTS_SYNCED=0
FAILED_GISTS_COUNT=0
declare -a FAILED_GISTS=()

while true; do
    PAGE_JSON=$(curl -sf -H "$API_AUTH_HEADER" "https://api.github.com/gists?per_page=100&page=${PAGE}" 2>/dev/null || true)
    ITEMS_COUNT=$(echo "$PAGE_JSON" | jq '. | length' 2>/dev/null || echo 0)

    if [ "$ITEMS_COUNT" -eq 0 ]; then
        break
    fi

    for i in $(seq 0 $((ITEMS_COUNT - 1))); do
        GIST_ID=$(echo "$PAGE_JSON" | jq -r ".[$i].id")
        GIST_DESC=$(echo "$PAGE_JSON" | jq -r ".[$i].description // \"(no description)\"" | cut -c 1-35)
        CLONE_URL="https://gist.github.com/${GIST_ID}.git"
        TARGET_DIR="${BACKUP_ROOT}/gists/${GIST_ID}.git"

        TOTAL_GISTS_SYNCED=$((TOTAL_GISTS_SYNCED + 1))
        printf "  -> [%02d] Gist %s (%-35s)... " "$TOTAL_GISTS_SYNCED" "$GIST_ID" "$GIST_DESC"

        if [ ! -d "$TARGET_DIR" ]; then
            if git -c http.extraHeader="$GIT_AUTH_HEADER" clone --mirror "$CLONE_URL" "$TARGET_DIR" >/dev/null 2>&1; then
                echo "[CLONED]"
            else
                echo "[FAILED CLONE]"
                FAILED_GISTS_COUNT=$((FAILED_GISTS_COUNT + 1))
                FAILED_GISTS+=("$GIST_ID")
            fi
        else
            if git -C "$TARGET_DIR" -c http.extraHeader="$GIT_AUTH_HEADER" remote update --prune >/dev/null 2>&1; then
                echo "[UPDATED]"
            else
                echo "[FAILED UPDATE]"
                FAILED_GISTS_COUNT=$((FAILED_GISTS_COUNT + 1))
                FAILED_GISTS+=("$GIST_ID")
            fi
        fi
    done

    PAGE=$((PAGE + 1))
done

echo ""

# 6. 生成并记录备份元数据
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
STATUS="success"
if [ "$FAILED_REPOS_COUNT" -gt 0 ] || [ "$FAILED_GISTS_COUNT" -gt 0 ]; then
    STATUS="completed_with_errors"
fi

cat <<EOF > "${BACKUP_ROOT}/latest_backup.json"
{
  "timestamp": "${END_TIME}",
  "user": "${GH_USER}",
  "status": "${STATUS}",
  "repos": {
    "total": ${TOTAL_REPOS_SYNCED},
    "failed": ${FAILED_REPOS_COUNT}
  },
  "gists": {
    "total": ${TOTAL_GISTS_SYNCED},
    "failed": ${FAILED_GISTS_COUNT}
  }
}
EOF

echo "=================================================================="
echo "          GitHub Mirror Backup Complete"
echo "          Finished: ${END_TIME}"
echo "          Repositories Synced : ${TOTAL_REPOS_SYNCED} (Failed: ${FAILED_REPOS_COUNT})"
echo "          Gists Synced        : ${TOTAL_GISTS_SYNCED} (Failed: ${FAILED_GISTS_COUNT})"
echo "          Status              : ${STATUS}"
echo "          Metadata saved to   : ${BACKUP_ROOT}/latest_backup.json"
echo "=================================================================="

if [ "$STATUS" != "success" ]; then
    if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
        echo "Failed Repositories:" >&2
        for r in "${FAILED_REPOS[@]}"; do
            echo "  - $r" >&2
        done
    fi
    if [ ${#FAILED_GISTS[@]} -gt 0 ]; then
        echo "Failed Gists:" >&2
        for g in "${FAILED_GISTS[@]}"; do
            echo "  - $g" >&2
        done
    fi
    exit 2
fi
