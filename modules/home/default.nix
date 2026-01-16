{ pkgs, ... }:
{
  imports = [
    ./fish.nix
    ./git.nix
    ./gpg.nix
    ./helix.nix
    ./tmux.nix
    ./tools.nix
    ./packages.nix
  ];

  home.stateVersion = "25.11";

  fonts.fontconfig.enable = true;
}
