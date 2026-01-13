{ pkgs, ... }:
{
  imports = [
    ./fish.nix
    ./git.nix
    ./helix.nix
    ./tmux.nix
    ./tools.nix
    ./packages.nix
  ];

  home.stateVersion = "25.11";
}
