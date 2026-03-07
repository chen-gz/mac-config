{ pkgs, lib, ... }:
{
  imports = [
    ./fish.nix
    ./git.nix
    ./gpg.nix
    ./ssh.nix
    ./helix.nix
    ./tmux.nix
    ./tools.nix
    ./packages.nix
  ] ++ (lib.optionals pkgs.stdenv.isDarwin [
    ./alacritty.nix
    ./ghostty.nix
  ]);

  home.stateVersion = "25.11";

  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = "hx";
    VISUAL = "hx";
  };

  fonts.fontconfig.enable = pkgs.stdenv.isDarwin;
}
