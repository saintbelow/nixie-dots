# /mnt/etc/nixos/flake.nix
{
  description = "NixOS configuration for nixie machine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Or "nixos-24.05" for stable

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
        url = "github:hyprwm/Hyprland"; # For latest Hyprland features if needed
        # Or remove this and use nixpkgs' version if stable enough
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs: {
    nixosConfigurations.nixie = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; }; # Pass inputs to configuration.nix
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; }; # Pass inputs to home.nix
          home-manager.users.saintbelow = import ./home.nix;
        }
        # Example of using hyprland input if you want to override nixpkgs' version
        # { programs.hyprland.package = inputs.hyprland.packages."x86_64-linux".hyprland; }
      ];
    };
  };
}
