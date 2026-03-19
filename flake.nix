{
  description = "Personal PC using Hyprland with Illogical Impulse";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    disko.url = "github:nix-community/disko";

    zen-browser = {
        url = "github:0xc000022070/zen-browser-flake";
        inputs = {
          nixpkgs.follows = "nixpkgs";
          home-manager.follows = "home-manager";
        };
      };
  };

  outputs = { self, nixpkgs, disko, home-manager,  ... }@inputs: {
    nixosConfigurations = {
      framework-13 = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         specialArgs = { inherit inputs; };
         modules = [
           home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true; # Use system pkgs -> save system space
              home-manager.useUserPackages = true; # Install to user profile
              home-manager.extraSpecialArgs = { inherit inputs; };
           }
           disko.nixosModules.disko
           ./hosts/framework-13
         ];
       };
    };
  };
}
