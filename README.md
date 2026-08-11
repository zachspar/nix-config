# nix-config

My NixOS / nix-darwin configuration for personal machines. This flake manages system configurations and home environments using Home Manager.

## Hosts

### Linux Hosts

- **maple** - Laptop
- **tumble** - Desktop workstation

All Linux hosts share `hosts/linux/common.nix` and can opt into features like DisplayLink. Hosts are **auto-discovered** from `hosts/linux/*/configuration.nix` — no `flake.nix` edit when adding a machine.

### Darwin Hosts

- **neo** - macOS (aarch64-darwin)

Darwin hosts are auto-discovered from `hosts/darwin/*/default.nix`.

## Structure

```
.
├── flake.nix              # Discovery, host factories, devShell, apps
├── scripts/
│   └── add-host           # Scaffold a new Linux host
├── templates/
│   └── linux/             # Templates used by add-host
├── home/                  # Home Manager configs
│   ├── common.nix         # Shared across all platforms
│   ├── linux.nix          # Linux-specific config
│   └── programs/          # Individual program configs
└── hosts/
    ├── darwin/
    │   └── neo/
    └── linux/
        ├── common.nix     # Shared NixOS baseline
        ├── maple/
        ├── tumble/
        └── programs/
            └── displaylink/
```

## Devshell

```bash
nix develop
```

Provides `add-host`, `nixfmt`, `nil`, `shellcheck`, `statix`, and `git`. The shell banner lists discovered hosts.

## Getting Started

### Initial Setup (existing host)

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

After the initial setup, use the `rebuild` alias:
```bash
rebuild
```

It detects your hostname and rebuilds (`/etc/nixos#$(hostname)`).

## Adding a New Linux Host

Hosts are registered by filesystem layout only. Prefer the scaffold tool:

```bash
# From the repo root
nix develop
add-host <hostname>

# Or without entering the shell
nix run .#add-host -- <hostname>

# Options
add-host --displaylink birch          # enable DisplayLink import
add-host --system aarch64-linux pi    # non-default arch (writes meta.nix)
```

What `add-host` does:

1. Creates `hosts/linux/<hostname>/configuration.nix` from the template (imports `common.nix`, sets hostname).
2. Writes `hardware-configuration.nix` via `nixos-generate-config` when available, otherwise a stub that fails evaluation with instructions.
3. Optionally writes `meta.nix` when `--system` is not `x86_64-linux`.

Then:

1. Customize the host config (LUKS, packages, ssh keys, …).
2. On the target machine, replace any hardware stub:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/linux/<hostname>/hardware-configuration.nix
   ```
3. Commit (flake only sees tracked files reliably):
   ```bash
   git add hosts/linux/<hostname> && git commit -m "Add host <hostname>"
   ```
4. Symlink and switch:
   ```bash
   sudo ln -sfn "$(pwd)" /etc/nixos
   sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
   ```

### Manual layout (without the script)

```
hosts/linux/<hostname>/
  configuration.nix          # required — discovered by the flake
  hardware-configuration.nix # required
  meta.nix                   # optional: { system = "aarch64-linux"; }
```

`configuration.nix` should import `../common.nix` and `./hardware-configuration.nix`.

## Features

### System Level
- Latest Linux kernel
- KDE Plasma 6 with Wayland
- Docker
- VM management with libvirtd/KVM (host-specific)
- DisplayLink dock support (opt-in)
- Automatic flakes support

### User Level (Home Manager)
- Consistent shell environment (bash with custom aliases)
- Git configuration
- Vim setup
- Development tools (kubectl, helm, talosctl, etc.)
- Plasma desktop customization

## Notes

- Nixpkgs tracks the branch set in `flake.nix` (currently nixos-26.05); Home Manager state version: 25.11
- Git tree must be clean or committed for rebuilds to pick up new files reliably
- DisplayLink prefetch script handles EULA acceptance for CI builds
- Optional `hosts/linux/<name>/meta.nix`: `{ system = "x86_64-linux"; }` overrides the default system for that host
