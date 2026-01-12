# The name of the configuration in flake.nix
flake_name := "guangzong-mac-mini"

# Default target to deploy the configuration
deploy: update
    nix run nix-darwin -- switch --flake .#{{flake_name}}

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
