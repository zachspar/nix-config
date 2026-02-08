# nix-config

My NixOS configuration for personal machines. This flake manages system configurations and home environments using Home Manager.

## Hosts

### Linux Hosts

- **maple** - Laptop
- **tumble** - Desktop workstation

All Linux hosts share common configuration and can opt into additional features like DisplayLink support.

## Structure

```
.
├── flake.nix              # Main flake configuration
├── home/                  # Home Manager configs
│   ├── common.nix         # Shared across all platforms
│   ├── linux.nix          # Linux-specific config
│   └── programs/          # Individual program configs
└── hosts/
    └── linux/
        ├── maple/         # Maple-specific config
        ├── tumble/        # Tumble-specific config
        └── programs/
            └── displaylink/  # DisplayLink dock support
```

## Getting Started

### Initial Setup

1. Clone this repo:
   ```bash
   git clone <your-repo-url> ~/Code/nix-config
   ```

2. Symlink to `/etc/nixos`:
   ```bash
   # Backup existing config
   sudo mv /etc/nixos /etc/nixos.backup
   
   # Create symlink
   sudo ln -s ~/Code/nix-config /etc/nixos
   ```

3. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
   ```

### Daily Usage

After the initial setup, just use the `rebuild` alias:
```bash
rebuild
```

It automatically detects your hostname and rebuilds the system.

## Features

### System Level
- Latest Linux kernel
- KDE Plasma 6 with Wayland
- Docker
- VM management with libvirtd/KVM
- DisplayLink dock support (opt-in)
- Automatic flakes support

### User Level (Home Manager)
- Consistent shell environment (bash with custom aliases)
- Git configuration
- Vim setup
- Development tools (kubectl, helm, talosctl, etc.)
- Plasma desktop customization

## Adding a New Host

1. Generate hardware config:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/linux/<hostname>/hardware-configuration.nix
   ```

2. Create `hosts/linux/<hostname>/configuration.nix` (copy from an existing host)

3. Add to `flake.nix`:
   ```nix
   <hostname> = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = { inherit inputs; };
     modules = [
       ./hosts/linux/<hostname>/configuration.nix
       # ... (copy module config from existing host)
     ];
   };
   ```

4. Rebuild!

## Notes

- The configuration uses NixOS 25.11 stable
- Home Manager state version: 25.11
- Git tree must be clean or committed for rebuilds to work properly
- DisplayLink prefetch script handles EULA acceptance for CI builds

