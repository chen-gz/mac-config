#!/bin/bash
# Install command: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/chen-gz/mac-config/main/bootstrap.sh)"

set -e

# Configuration
REPO_URL="https://github.com/chen-gz/mac-config"
TARGET_DIR="$HOME/.config/nix-darwin"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    printf "${BLUE}[BOOTSTRAP]${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

# 0. Detect OS
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    FLAKE_NAME="mac-mini"
    log "Detected macOS. Using flake: $FLAKE_NAME"
else
    FLAKE_NAME="linux-server"
    log "Detected Linux. Using flake: $FLAKE_NAME"
fi

# 1. Install Nix if needed
if ! command -v nix >/dev/null 2>&1; then
    log "Nix not found. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install | sh
    
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
else
    log "Nix is already installed."
fi

# 2. Ensure experimental features are enabled for the first run
if ! nix show-config 2>/dev/null | grep -q "experimental-features = .*flakes"; then
    log "Enabling experimental features (flakes)..."
    export NIX_CONFIG="experimental-features = nix-command flakes"
fi

# 3. Clone or Update Configuration
if [ ! -d "$TARGET_DIR" ]; then
    log "Cloning configuration to $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"
else
    log "Configuration directory $TARGET_DIR already exists."
    # Optional: git -C "$TARGET_DIR" pull
fi

# 4. Build and Switch
log "Building and switching configuration for ${FLAKE_NAME}..."

if [ "$OS" = "Darwin" ]; then
    # MacOS: Run nix-darwin
    sudo -H nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake "${TARGET_DIR}#${FLAKE_NAME}"
else
    # Linux: Run home-manager
    # We use 'nix run' to execute home-manager without installing it permanently in the user profile first
    nix run github:nix-community/home-manager --extra-experimental-features "nix-command flakes" -- switch -b backup --impure --flake "${TARGET_DIR}#${FLAKE_NAME}"
fi

success "Setup complete! Please restart your shell."
