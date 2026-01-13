# Detect Operating System
os := `uname -s`

# Configuration names
darwin_flake := "guangzong-mac-mini"
linux_flake := "guangzong"

# List all available commands
default:
    @just --list

# Deploy the configuration based on the OS (macOS -> nix-darwin, Linux -> home-manager)
deploy:
    @if [ "{{os}}" = "Darwin" ]; then \
        echo "🍎 Detected macOS. Deploying nix-darwin configuration ({{darwin_flake}})..."; \
<<<<<<< HEAD
        nix run nix-darwin -- switch --flake .#{{darwin_flake}}; \
=======
        sudo -H nix run nix-darwin -- switch --flake .#{{darwin_flake}}; \
>>>>>>> 88325c0 (update just file)
    else \
        echo "🐧 Detected Linux. Deploying Home Manager configuration ({{linux_flake}})..."; \
        nix run github:nix-community/home-manager -- switch --flake .#{{linux_flake}}; \
    fi

# Update flake.lock inputs to the latest versions
update:
    nix flake update

# Verify the flake for errors
check:
    nix flake check

# Format all Nix files using nixfmt
format:
    nix fmt

# Clean up old Nix generations and garbage collect
clean:
    nix-collect-garbage -d

