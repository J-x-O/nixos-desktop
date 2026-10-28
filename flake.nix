{
  description = "Personal PC using Hyprland with Illogical Impulse";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned so `nix flake update` doesn't force a new Godot version on the team.
    # Bump this rev deliberately when everyone agrees to update.
    nixpkgs-godot.url = "github:nixos/nixpkgs/6258c89d88bc4ca97f955b7b47b8f828d091ecdc";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    illogical-flake = {
      url = "github:J-x-O/illogical-flake/a62d694cb7e6b747437b9bc6e3c68ffc6c146d5c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    photogimp = {
      url = "github:Diolinux/PhotoGIMP";
      flake = false;
    };
    # RemoteDesktop portal for KDE Connect remote input; see modules/software/kdeconnect.nix
    hypr-kdeconnect-fix = {
      url = "github:boscovn/hypr-kdeconnect-fix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zed-netcoredbg = {
      url = "github:qwadrox/zed-netcoredbg";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, photogimp, zed-netcoredbg, ... }@inputs:
  let
    vars = import ./vars.nix;
  in {
    nixosConfigurations = {
      framework-13 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars photogimp zed-netcoredbg; };
        modules = [
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs vars; };
          }
          disko.nixosModules.disko
          ./hosts/framework-13
        ];
      };
      tower = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars photogimp zed-netcoredbg; };
        modules = [
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true; # Use system pkgs -> save system space
            home-manager.useUserPackages = true; # Install to user profile
            home-manager.extraSpecialArgs = { inherit inputs vars; };
          }
          disko.nixosModules.disko
          ./hosts/tower
        ];
      };
    };
  };
}
