#!/usr/bin/bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
nix run nix-darwin -- switch --flake .#mac-mini
sudo darwin-rebuild switch --flake .
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#mac-mini
sudo -H nix run nix-darwin -- switch --flake .#mac-mini
