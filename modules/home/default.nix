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
    ./ssh.nix
  ];

  home.stateVersion = "25.11";

  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = "hx";
    VISUAL = "hx";
  };

  fonts.fontconfig.enable = true;
}
