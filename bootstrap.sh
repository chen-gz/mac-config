#!/bin/bash
set -e

# Configuration
FLAKE_NAME="guangzong-mac-mini"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[BOOTSTRAP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 1. Install Nix if needed
if ! command -v nix &> /dev/null; then
    log "Nix not found. Installing..."
    sh <(curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install)
    
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

# 3. Build and Switch
log "Building and switching configuration for ${FLAKE_NAME}..."
# Use --extra-experimental-features to be safe even if NIX_CONFIG isn't enough for some reason
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ".#${FLAKE_NAME}"

success "Setup complete! Please restart your shell."
