# Detect Operating System

os := `uname -s`

# Configuration names

darwin_flake := "guangzong-mac-mini"
linux_flake := "guangzong"

# Default target to deploy the configuration
deploy:
    @if [ "{{ os }}" = "Darwin" ]; then \
        echo "🍎 Detected macOS. Deploying nix-darwin configuration ({{ darwin_flake }})..."; \
        sudo -H nix run nix-darwin -- switch --flake .#{{ darwin_flake }}; \
    else \
        echo "🐧 Detected Linux. Deploying Home Manager configuration ({{ linux_flake }})..."; \
        nix run github:nix-community/home-manager -- switch --flake .#{{ linux_flake }}; \
    fi

# Update flake inputs
update:
    nix flake update

# Check flake
check:
    nix flake check

# Format nix files
format:
    nix fmt

# Clean up garbage
clean:
    nix-collect-garbage -d
