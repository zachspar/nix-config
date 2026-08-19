{
  description = "NixOS configuration for my personal machines";

  inputs = {
    # Nixpkgs stable release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Home Manager — use branch matching nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

    # nix-darwin (macOS) — use branch matching nixpkgs
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning (used by nixos-anywhere installs)
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Encrypted secrets (age); decrypted at activation, not evaluation
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-pkgs, nix-darwin, disko, ... }@inputs:
  let
    inherit (nixpkgs) lib;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    forAllSystems = lib.genAttrs systems;

    pkgsFor = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Named shells under devshells/*.nix. Attribute name is the filename
    # without .nix. `default.nix` is reserved for the nix-config shell below.
    extraDevShellFiles = lib.attrNames (
      lib.filterAttrs (
        name: type:
        type == "regular"
        && lib.hasSuffix ".nix" name
        && name != "default.nix"
      ) (builtins.readDir ./devshells)
    );

    mkExtraDevShells = pkgs:
      lib.listToAttrs (
        map (file: {
          name = lib.removeSuffix ".nix" file;
          value = import (./devshells + "/${file}") { inherit pkgs; };
        }) extraDevShellFiles
      );

    # Directories under hosts/linux that contain configuration.nix (skip programs/)
    linuxHostNames = lib.attrNames (
      lib.filterAttrs (
        name: type:
        type == "directory"
        && name != "programs"
        && builtins.pathExists (./hosts/linux + "/${name}/configuration.nix")
      ) (builtins.readDir ./hosts/linux)
    );

    # Directories under hosts/darwin that contain default.nix
    darwinHostNames = lib.attrNames (
      lib.filterAttrs (
        name: type:
        type == "directory"
        && builtins.pathExists (./hosts/darwin + "/${name}/default.nix")
      ) (builtins.readDir ./hosts/darwin)
    );

    # Optional per-host meta: { system = "x86_64-linux"; }
    linuxHostMeta = hostname:
      let
        metaPath = ./hosts/linux + "/${hostname}/meta.nix";
      in
      if builtins.pathExists metaPath then import metaPath else { };

    mkNixosHost = hostname:
      let
        meta = linuxHostMeta hostname;
        system = meta.system or "x86_64-linux";
        headless = meta.headless or false;
        # Opt out with `sops = false` until the host SSH key is a recipient
        # in .sops.yaml (bootstrap, and new nixos-anywhere installs).
        sopsEnabled = meta.sops or true;
        homeImports =
          if headless then
            [ ./home/server.nix ]
          else
            [
              ./home/linux.nix
              inputs.plasma-manager.homeModules.plasma-manager
            ];
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ nix-pkgs.overlays.default ]; }
          disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          (./hosts/linux + "/${hostname}/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.zspar = { pkgs, ... }: {
              imports = homeImports;
              home.stateVersion = "25.11";
            };
          }
        ] ++ lib.optionals sopsEnabled [
          ./hosts/linux/sops.nix
        ];
      };

    # Optional per-host meta for darwin: { system = "aarch64-darwin"; }
    darwinHostMeta = hostname:
      let
        metaPath = ./hosts/darwin + "/${hostname}/meta.nix";
      in
      if builtins.pathExists metaPath then import metaPath else { };

    mkDarwinHost = hostname:
      let
        meta = darwinHostMeta hostname;
        system = meta.system or "aarch64-darwin";
      in
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ nix-pkgs.overlays.default ]; }
          (./hosts/darwin + "/${hostname}/default.nix")
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

    # Wrap scripts/add-host so runtime tools are available; script resolves
    # the writable repo root from $PWD (not the /nix/store flake copy).
    addHostScript = system:
      let
        pkgs = pkgsFor system;
      in
      pkgs.writeShellApplication {
        name = "add-host";
        runtimeInputs = [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.bash ];
        text = ''
          exec bash ${./scripts/add-host} "$@"
        '';
      };

    # Wrap scripts/bootstrap-host; installs a host with nixos-anywhere.
    bootstrapHostScript = system:
      let
        pkgs = pkgsFor system;
      in
      pkgs.writeShellApplication {
        name = "bootstrap-host";
        runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.bash pkgs.nix ];
        text = ''
          exec bash ${./scripts/bootstrap-host} "$@"
        '';
      };
  in
  {
    nixosConfigurations = lib.genAttrs linuxHostNames mkNixosHost;

    darwinConfigurations = lib.genAttrs darwinHostNames mkDarwinHost;

    apps = forAllSystems (system: {
      add-host = {
        type = "app";
        program = lib.getExe (addHostScript system);
      };
      bootstrap-host = {
        type = "app";
        program = lib.getExe (bootstrapHostScript system);
      };
    });

    devShells = forAllSystems (
      system:
      let
        pkgs = pkgsFor system;
        add-host = addHostScript system;
        bootstrap-host = bootstrapHostScript system;
      in
      {
        default = pkgs.mkShell {
          name = "nix-config";
          packages = with pkgs; [
            git
            nixfmt
            nil
            shellcheck
            statix
            add-host
            bootstrap-host
            nixos-anywhere
            nixos-rebuild
            sops
            age
            ssh-to-age
            mkpasswd
          ];
          shellHook = ''
            echo "nix-config devshell"
            echo "  Linux hosts:  ${lib.concatStringsSep ", " linuxHostNames}"
            echo "  Darwin hosts: ${lib.concatStringsSep ", " darwinHostNames}"
            echo ""
            echo "  add-host <hostname>          scaffold a new Linux host"
            echo "  bootstrap-host <host> <ip>   install a host via nixos-anywhere"
            echo "  sops secrets/common.yaml     edit encrypted secrets"
            echo "  sops updatekeys secrets/*.yaml"
            echo "  ssh-to-age                   convert a host SSH pubkey to age"
            echo "  mkpasswd -m yescrypt         hash a login password"
            echo "  nixfmt                       format Nix files"
            echo "  shellcheck scripts/*         lint scripts"
            echo ""
          '';
        };
      }
      // mkExtraDevShells pkgs
    );
  };
}
