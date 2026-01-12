{
  description = "Linux server configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Import the root flake to reuse modules
    # Assuming the root flake is one level up
    root-flake.url = "path:..";
  };

  outputs = { self, nixpkgs, home-manager, root-flake, ... }:
  let
    username = "guangzong";
    system = "x86_64-linux"; # Standard server arch, user can change if needed
  in
  {
    nixosConfigurations.linux-server = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # Common packages from the root flake
        root-flake.nixosModules.common

        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Reuse the home module from the root flake
          home-manager.users."${username}" = root-flake.nixosModules.home;
        }
      ];
    };
  };
}
