#!/usr/bin/env bash
# Install command: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/chen-gz/mac-config/main/bootstrap.sh)"

set -e

# Increase file descriptor limit for handling large flake inputs (e.g., homebrew-core)
ulimit -n 4096 2>/dev/null || true

# Configuration
REPO_URL="https://github.com/chen-gz/mac-config"
DEFAULT_TARGET_DIR="$HOME/.config/nix-darwin"

# Detect if the script is being run from a local checkout
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "$SCRIPT_DIR/flake.nix" ]; then
    TARGET_DIR="$SCRIPT_DIR"
else
    TARGET_DIR="$DEFAULT_TARGET_DIR"
fi

# Enable experimental features for all Nix commands
export NIX_CONFIG="experimental-features = nix-command flakes"
export NIXPKGS_ALLOW_UNFREE=1

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

# 1. Install Nix
install_nix() {
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

    if nix show-config 2>/dev/null | grep -E "(experimental-features|extra-experimental-features) = .*flakes" >/dev/null; then
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
    FLAKE_NAME="$1"

    if [ -z "$FLAKE_NAME" ]; then
        echo "Error: Configuration name is required."
        echo "Usage: $0 deploy <config-name>"
        list_configs
        exit 1
    fi

    shift # Remove FLAKE_NAME from arguments

    log "Building and switching configuration for ${FLAKE_NAME}..."
    
    # macOS pre-flight: ensure /etc/synthetic.conf exists
    if [ ! -e /etc/synthetic.conf ]; then
        log "/etc/synthetic.conf not found — creating empty file with correct ownership/permissions"
        sudo touch /etc/synthetic.conf
        sudo chown root:wheel /etc/synthetic.conf || true
        sudo chmod 644 /etc/synthetic.conf || true
    fi
    
    echo "🍎 Detected macOS. Deploying nix-darwin configuration (${FLAKE_NAME})..."
    # Use sudo to ensure we have permissions, but pass through necessary environment variables
    if [[ "$*" == *"--target-host"* ]]; then
        nix run nix-darwin -- switch --flake "${TARGET_DIR}#${FLAKE_NAME}" "$@"
    else
        sudo NIX_CONFIG="$NIX_CONFIG" NIXPKGS_ALLOW_UNFREE="$NIXPKGS_ALLOW_UNFREE" bash -c "ulimit -n 4096 2>/dev/null || true; nix run nix-darwin -- switch --flake '${TARGET_DIR}#${FLAKE_NAME}' $*"
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
    log "Cleaning user generations..."
    nix-collect-garbage -d
    log "Cleaning system generations (requires sudo)..."
    sudo nix-collect-garbage -d
}

list_configs() {
    log "Available configurations in flake.nix:"
    if [ -f "${TARGET_DIR}/flake.nix" ]; then
        grep -E '"[^"]+" =' "${TARGET_DIR}/flake.nix" | grep -v 'formatter' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^/  - /'
    else
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "https://raw.githubusercontent.com/chen-gz/mac-config/main/flake.nix" 2>/dev/null | grep -E '"[^"]+" =' | grep -v 'formatter' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^/  - /' || echo "  (Could not fetch configurations remotely)"
        else
            echo "  (Configuration not cloned yet. Run with a configuration name to bootstrap)"
        fi
    fi
}

help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)          Show this help"
    echo "  deploy <config>    Deploy the configuration (Switch)"
    echo "  update             Update flake.lock inputs"
    echo "  check              Verify the flake"
    echo "  format             Format Nix files"
    echo "  clean              Garbage collect old generations"
    echo ""
    list_configs
}

# Main Dispatch
if [ $# -eq 0 ]; then
    help
else
    case "$1" in
        deploy) shift; deploy "$@" ;; 
        update) update ;; 
        check) check ;; 
        format) format ;; 
        clean) clean ;; 
        help|--help|-h) help ;; 
        *)
            # If the first argument is not a command, assume it is a config name for full bootstrap
            FLAKE_NAME="$1"
            shift # Remaining arguments if any
            install_nix
            ensure_config
            deploy "$FLAKE_NAME" "$@"
            success "Setup complete! Please restart your shell."
            ;;
    esac
fi
