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

# 0. Detect OS and set variables
detect_os() {
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        FLAKE_NAME="mac-mini"
    else
        FLAKE_NAME="linux-server"
    fi
}

# 1. Install Nix
install_nix() {
    detect_os
    if [ "$OS" = "Darwin" ]; then
        # Ensure Xcode Command Line Tools are installed (macOS specific)
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
    fi

    if ! command -v nix >/dev/null 2>&1; then
        log "Nix not found. Installing..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
        
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        fi

        if ! command -v nix >/dev/null 2>&1; then
            export PATH="/nix/var/nix/profiles/default/bin:$PATH"
        fi
    else
        log "Nix is already installed."
    fi

    # Enable experimental features
    export NIX_CONFIG="experimental-features = nix-command flakes"
    if nix show-config 2>/dev/null | grep -q "experimental-features = .*flakes"; then
        log "Experimental features (flakes) are enabled."
    else
        log "Warning: Could not confirm experimental features are enabled."
    fi
}

# 2. Clone or Update Configuration
ensure_config() {
    if [ ! -d "$TARGET_DIR" ]; then
        log "Cloning configuration to $TARGET_DIR..."
        if command -v git >/dev/null 2>&1; then
            git clone "$REPO_URL" "$TARGET_DIR"
        else
            log "System git not found. Using Nix to clone..."
            nix run nixpkgs#git -- clone "$REPO_URL" "$TARGET_DIR"
        fi
    else
        log "Configuration directory $TARGET_DIR already exists."
    fi
}

# 3. Operations
deploy() {
    detect_os
    log "Building and switching configuration for ${FLAKE_NAME}..."
    
    # macOS pre-flight: ensure /etc/synthetic.conf exists
    if [ "$OS" = "Darwin" ]; then
        if [ ! -e /etc/synthetic.conf ]; then
            log "/etc/synthetic.conf not found — creating empty file with correct ownership/permissions"
            sudo touch /etc/synthetic.conf
            sudo chown root:wheel /etc/synthetic.conf || true
            sudo chmod 644 /etc/synthetic.conf || true
        fi
        
        echo "🍎 Detected macOS. Deploying nix-darwin configuration (${FLAKE_NAME})..."
        # Re-using the exact command from justfile/bootstrap but ensuring we point to TARGET_DIR
        sudo nix run nix-darwin -- switch --flake "${TARGET_DIR}#${FLAKE_NAME}"
    else
        echo "🐧 Detected Linux. Deploying Home Manager configuration (${FLAKE_NAME})..."
        nix run github:nix-community/home-manager --extra-experimental-features "nix-command flakes" -- switch -b backup --impure --flake "${TARGET_DIR}#${FLAKE_NAME}"
    fi
}

update() {
    log "Updating flake inputs..."
    cd "$TARGET_DIR" && nix flake update
}

check() {
    log "Checking flake for errors..."
    cd "$TARGET_DIR" && nix flake check
}

format() {
    log "Formatting all Nix files..."
    cd "$TARGET_DIR" && nix fmt
}

clean() {
    log "Cleaning up old generations and garbage collecting..."
    nix-collect-garbage -d
}

help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)  Full bootstrap: Install Nix, Clone Config, Deploy"
    echo "  deploy     Deploy the configuration (Switch)"
    echo "  update     Update flake.lock inputs"
    echo "  check      Verify the flake"
    echo "  format     Format Nix files"
    echo "  clean      Garbage collect old generations"
}

# Main Dispatch
if [ $# -eq 0 ]; then
    # Default behavior: Bootstrap
    install_nix
    ensure_config
    deploy
    success "Setup complete! Please restart your shell."
else
    case "$1" in
        deploy) deploy ;; 
        update) update ;; 
        check) check ;; 
        format) format ;; 
        clean) clean ;; 
        help|--help|-h) help ;; 
        *) echo "Unknown command: $1"; help; exit 1 ;; 
    esac
fi
