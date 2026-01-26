{
  description = "NixOS configuration for my personal machines";

  inputs = {
    # NixOS stable release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      maple = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/maple/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
  };
}

