{ pkgs, lib, ... }:
{
  imports = [
    ./modules/home/common.nix
  ];

  programs.git.settings.user = {
    name = "Connie";
    email = "connie@example.com";
    # signingkey = "...";
  };
}
