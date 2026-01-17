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

    # Ensure Xcode Command Line Tools are installed
    if ! xcode-select -p >/dev/null 2>&1; then
        log "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        echo "---------------------------------------------------------"
        echo "Action Required: Please complete the installation in the pop-up window."
        echo "Press [Enter] key here when the installation is finished..."
        echo "---------------------------------------------------------"
        read -r
    else
        log "Xcode Command Line Tools already installed."
    fi
else
    FLAKE_NAME="linux-server"
    log "Detected Linux. Using flake: $FLAKE_NAME"
fi

# 1. Install Nix if needed
if ! command -v nix >/dev/null 2>&1; then
    log "Nix not found. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    
    # Source nix profile to make it available in current shell
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi

    # Manual path fallback if sourcing didn't work for the current subshell
    if ! command -v nix >/dev/null 2>&1; then
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"
    fi
else
    log "Nix is already installed."
fi

# 2. Ensure experimental features are enabled for the first run
# This is critical for section 3 and 4 to work
export NIX_CONFIG="experimental-features = nix-command flakes"
if nix show-config 2>/dev/null | grep -q "experimental-features = .*flakes"; then
    log "Experimental features (flakes) are enabled."
else
    log "Warning: Could not confirm experimental features are enabled."
fi

# 3. Clone or Update Configuration
if [ ! -d "$TARGET_DIR" ]; then
    log "Cloning configuration to $TARGET_DIR..."
    
    # Try system git first, then fallback to nix-bundled git
    if command -v git >/dev/null 2>&1; then
        git clone "$REPO_URL" "$TARGET_DIR"
    else
        log "System git not found. Using Nix to clone..."
        nix run nixpkgs#git -- clone "$REPO_URL" "$TARGET_DIR"
    fi
else
    log "Configuration directory $TARGET_DIR already exists."
    # Optional: git -C "$TARGET_DIR" pull
fi

# macOS pre-flight: ensure /etc/synthetic.conf exists (some activations assume it exists)
if [ "$OS" = "Darwin" ]; then
    if [ ! -e /etc/synthetic.conf ]; then
        log "/etc/synthetic.conf not found — creating empty file with correct ownership/permissions"
        # Use sudo since /etc is root-owned; tolerate failures to avoid breaking unattended runs
        sudo touch /etc/synthetic.conf
        sudo chown root:wheel /etc/synthetic.conf || true
        sudo chmod 644 /etc/synthetic.conf || true
    fi
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
