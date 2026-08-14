# nix-config

My NixOS / nix-darwin configuration for personal machines. This flake manages system configurations and home environments using Home Manager.

## Hosts

### Linux Hosts

- **maple** - Laptop
- **tumble** - Desktop workstation
- **flakey** - Headless server
- **bootstrap** - Generic headless install target for nixos-anywhere (not a real machine)

All Linux hosts share `hosts/linux/base.nix`. Desktop hosts add `hosts/linux/common.nix` (Plasma, printing, audio) and can opt into features like DisplayLink; headless servers add `hosts/linux/server-common.nix` (hardened SSH, firmware-agnostic bootloader). Hosts are **auto-discovered** from `hosts/linux/*/configuration.nix` — no `flake.nix` edit when adding a machine.

### Darwin Hosts

- **neo** - macOS (aarch64-darwin)

Darwin hosts are auto-discovered from `hosts/darwin/*/default.nix`.

## Structure

```
.
├── flake.nix              # Discovery, host factories, devShell, apps
├── .sops.yaml             # Public age recipients + creation rules
├── docs/
│   └── adding-secrets.md  # How to add and enroll sops secrets
├── secrets/
│   └── common.yaml        # Encrypted secrets (safe to commit)
├── scripts/
│   ├── add-host           # Scaffold a new Linux host (desktop or server)
│   └── bootstrap-host     # Install a host remotely via nixos-anywhere
├── templates/
│   └── linux/             # Templates used by add-host
├── home/                  # Home Manager configs
│   ├── common.nix         # Shared across all platforms
│   ├── linux.nix          # Linux desktop config (Plasma, GUI apps)
│   ├── server.nix         # Headless config (no GUI)
│   └── programs/          # Individual program configs
└── hosts/
    ├── darwin/
    │   └── neo/
    └── linux/
        ├── base.nix            # Headless-safe NixOS baseline
        ├── sops.nix            # sops-nix + hashedPasswordFile (enrolled hosts)
        ├── common.nix          # Desktop baseline (imports base.nix)
        ├── server-common.nix   # Server baseline (imports base.nix)
        ├── boot/               # Bootloader modules (bios-uefi.nix)
        ├── disko/              # Declarative disk layouts
        ├── bootstrap/          # Generic nixos-anywhere install target
        ├── maple/
        ├── tumble/
        ├── flakey/
        └── programs/
            └── displaylink/
```

## Devshell

```bash
nix develop
```

Provides `add-host`, `bootstrap-host`, `nixos-anywhere`, `nixos-rebuild`, `sops`, `age`, `ssh-to-age`, `mkpasswd`, `nixfmt`, `nil`, `shellcheck`, `statix`, and `git`. The shell banner lists discovered hosts.

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
add-host --displaylink <hostname>            # enable DisplayLink import
add-host --system aarch64-linux <hostname>   # non-default arch (writes meta.nix)
add-host --server <hostname>                 # headless server (see below)
add-host --server --disk /dev/nvme0n1 <hostname>
```

What `add-host` does:

1. Creates `hosts/linux/<hostname>/configuration.nix` from the template (imports `common.nix`, sets hostname).
2. Writes `hardware-configuration.nix` via `nixos-generate-config` when available, otherwise a stub that fails evaluation with instructions.
3. Writes `meta.nix` with `sops = false` (and `system` when `--system` is not `x86_64-linux`).

With `--server` it instead uses the server template (imports `server-common.nix` + the disko layout, sets the target disk), writes a bootable generic hardware stub that the install replaces, and always writes `meta.nix` with `headless = true` and `sops = false`.

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
  meta.nix                   # optional: { system = "aarch64-linux"; headless = true; sops = false; }
```

`configuration.nix` should import `../common.nix` (desktop) or `../server-common.nix` (headless) plus `./hardware-configuration.nix`. Setting `headless = true` in `meta.nix` selects the server Home Manager profile (`home/server.nix`, no Plasma/GUI apps). `sops = false` (the add-host default) skips the login password until the host SSH key is enrolled; `sops = true` applies `hashedPasswordFile` from `secrets/common.yaml`.

## Headless Servers (nixos-anywhere)

New machines can be provisioned remotely in one shot with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and [disko](https://github.com/nix-community/disko). Server hosts import `server-common.nix` (key-only SSH for `zspar` and `root`, Tailscale, firmware-agnostic bootloader via `hosts/linux/boot/bios-uefi.nix`) and a declarative disk layout from `hosts/linux/disko/` (single-disk GPT, 1G ESP + ext4 root; hybrid BIOS boot partition so the same config boots on BIOS and UEFI firmware).

### Prerequisites

The target must be reachable over SSH as root, booted into either:

- the NixOS installer ISO (`sudo passwd root` in the live console first), or
- any existing Linux distro — nixos-anywhere kexecs it into an in-memory NixOS installer (needs ~1.5 GB RAM; the old OS is destroyed). Copy your key first: `ssh-copy-id root@<ip>`.

Check the disk name on the target with `lsblk` (`sda`, `nvme0n1`, `vda`, …).

**Secure Boot must be disabled** on the target. With it enabled, kexec refuses the unsigned NixOS kernel (`kexec_file: Enforced kernel signature verification failed`) and the installed system wouldn't boot either, since NixOS bootloaders are unsigned. On Proxmox, use an EFI disk without pre-enrolled keys or disable Secure Boot in the OVMF firmware menu.

### Install

```bash
nix develop

# 1. Scaffold the host (disko + SSH, no desktop)
add-host --server <hostname> --disk /dev/sda
git add hosts/linux/<hostname> && git commit -m "Add host <hostname>"

# 2. Install — WARNING: wipes the target disk
bootstrap-host <hostname> root@<ip>

# 3. Commit the hardware config generated during the install
git add hosts/linux/<hostname>/hardware-configuration.nix
git commit -m "Add <hostname> hardware config"

# 4. Shell in
ssh zspar@<ip>
```

`bootstrap-host` runs nixos-anywhere with `--build-on-remote` (required when driving installs from macOS) and `--generate-hardware-config`, which writes the target's real `hardware-configuration.nix` into the host directory before the system is built. Filesystems stay disko-owned. Extra arguments are passed through to nixos-anywhere (e.g. `--env-password` with `SSHPASS` for password-only targets).

Notes:

- If the target kexecs from another distro, it re-runs DHCP and may come back on a **different IP** — check your router's leases and point `bootstrap-host` at the new address; nixos-anywhere skips the kexec step when the target is already in the installer.
- Consider a DHCP reservation, or run `sudo tailscale up` on the new host once and use its Tailscale name instead of the LAN IP.

### Generic bootstrap target

To bring a box up before deciding its identity, install the built-in generic config (hostname `bootstrap`, disk `/dev/sda`):

```bash
bootstrap-host bootstrap root@<ip>
```

Later, scaffold a real host with `add-host --server` and re-deploy onto it with `nixos-rebuild --target-host`.

### Day-2 management

Deploy config changes over SSH from the repo (no repo clone needed on the server):

```bash
TMPDIR=/tmp nixos-rebuild switch --flake .#<hostname> --target-host zspar@<host> \
  --use-remote-sudo --build-host zspar@<host>
```

`--build-host` builds on the target (macOS can't build x86_64-linux); `TMPDIR=/tmp` keeps the SSH control socket path under macOS's Unix socket length limit.

## Features

### System Level
- Latest Linux kernel
- KDE Plasma 6 with Wayland (desktop hosts)
- Encrypted secrets via sops-nix / age (login password hashes; decrypted at activation)
- Headless server baseline with hardened SSH and declarative disks (disko)
- Remote provisioning via nixos-anywhere
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
- Optional `hosts/linux/<name>/meta.nix`: `{ system = "x86_64-linux"; }` overrides the default system for that host; `headless = true` selects the server Home Manager profile; `sops = true` applies the encrypted login password (default is on if the flag is omitted)

## Secrets (sops-nix)

Login passwords are a **yescrypt hash** stored in `secrets/common.yaml` and encrypted with [age](https://age-encryption.org) via [sops](https://github.com/getsops/sops). The file is regular YAML in this public repo; values are `ENC[...]`. Evaluation and CI do not need any private key. Decryption happens at activation on enrolled machines, using the SSH host ed25519 key.

How to add a secret, declare it in Nix, and enroll a host: [docs/adding-secrets.md](docs/adding-secrets.md).

The admin key used to *edit* secrets lives only on neo:

```
~/.config/sops/age/keys.txt
```

Never commit that file.

### Set or change the `zspar` password

```bash
nix develop
mkpasswd -m yescrypt          # paste the hash into the file below
sops secrets/common.yaml      # replace users.zspar.hashedPassword
```

On enrolled hosts (`sops = true` in `meta.nix`), `users.mutableUsers = false`, so this hash is the source of truth. `passwd` will not stick.

**Do not `nixos-rebuild switch` an enrolled host until the hash is a real `mkpasswd` value.** The committed file starts as a placeholder.

### Enroll a host

The machine must already have `/etc/ssh/ssh_host_ed25519_key` (OpenSSH is enabled in `base.nix`).

```bash
nix develop
ssh zspar@<host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
```

1. Add the `age1…` public key to `.sops.yaml` (`keys:` plus the `secrets/common.yaml` creation rule).
2. `sops updatekeys secrets/common.yaml`
3. Set `sops = true` in `hosts/linux/<host>/meta.nix` (remove `sops = false`).
4. Commit `.sops.yaml`, `secrets/common.yaml`, and `meta.nix`, then rebuild that host.

`bootstrap` stays `sops = false` permanently — its host key is generated at install time and is not a recipient. New hosts from `add-host` also start with `sops = false`.

maple and tumble were offline when this was added, so they are opted out until enrolled. flakey’s host key is already a recipient; set `sops = true` in its `meta.nix` after the real hash is in `secrets/common.yaml`.
