{
  description = "NixOS configuration for my personal machines";

  inputs = {
    # Nixpkgs stable release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Custom packages
    nix-pkgs = {
      url = "github:zachspar/nix-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin (macOS) — use branch matching nixpkgs (25.11)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-pkgs, nix-darwin, ... }@inputs: {
    # NixOS configurations (x86_64-linux)
    nixosConfigurations = {
      maple = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Apply nix-pkgs overlay
          { nixpkgs.overlays = [ nix-pkgs.overlays.default ]; }
          ./hosts/linux/maple/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.zspar = { pkgs, ... }: {
              imports = [
                ./home/linux.nix
                inputs.plasma-manager.homeModules.plasma-manager
              ];
              home.stateVersion = "25.11";
            };
          }
        ];
      };
      tumble = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Apply nix-pkgs overlay
          { nixpkgs.overlays = [ nix-pkgs.overlays.default ]; }
          ./hosts/linux/tumble/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.zspar = { pkgs, ... }: {
              imports = [
                ./home/linux.nix
                inputs.plasma-manager.homeModules.plasma-manager
              ];
              home.stateVersion = "25.11";
            };
          }
        ];
      };
    };

    # Darwin configurations (aarch64-darwin / x86_64-darwin)
    darwinConfigurations = {
      neo = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          # Apply nix-pkgs overlay
          { nixpkgs.overlays = [ nix-pkgs.overlays.default ]; }
          ./hosts/darwin/neo/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.zspar = { pkgs, ... }: {
              imports = [ ./home/darwin.nix ];
              home.stateVersion = "25.11";
            };
          }
        ];
      };
    };
  };
}
