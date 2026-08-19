# Devshells

Named shells are auto-discovered from `devshells/*.nix` (filename without `.nix` is the attribute). The `default` nix-config shell is defined in `flake.nix`.

Enter from this repo, `/etc/nixos`, or GitHub:

```bash
nix develop                         # default (nix-config tooling)
nix develop .#<name>
nix develop /etc/nixos#<name>
nix develop github:zachspar/nix-config#<name>
```

Drop a new `devshells/<name>.nix` that takes `{ pkgs }` and returns `pkgs.mkShell { ... }` — no `flake.nix` edit. `default.nix` is reserved for the flake-owned shell.

## default

```bash
nix develop
```

Provides `add-host`, `bootstrap-host`, `nixos-anywhere`, `nixos-rebuild`, `sops`, `age`, `ssh-to-age`, `mkpasswd`, `nixfmt`, `nil`, `shellcheck`, `statix`, and `git`. The shell banner lists discovered hosts.

## kata-containers

```bash
nix develop .#kata-containers
```

Kernel-build tools plus helpers for the GitHub static Kata release (currently 4.0.0) and a local containerd install:

```bash
kata-install [-y] [VERSION]   # static release → /opt/kata, CNI plugins → /opt/cni/bin
kata-ubuntu [--keep]          # interactive Ubuntu shell via the Kata runtime
kata-status
kata-cleanup                  # leftover containers, cache, /opt/kata, and /opt/cni
```

The GitHub static binaries are generic Linux ELFs. On NixOS the host needs `programs.nix-ld.enable` and those `NIX_LD*` variables on the containerd unit (birch-cw already sets this) plus a rebuild.

`kata-ubuntu` uses **nerdctl** (not `ctr --cni` — that cannot join the netns into a Kata VM) with plugins from `/opt/cni/bin`, the `kata-net` bridge (`cni0` / `10.88.0.0/16`), and DNS that is not systemd-resolved’s `127.0.0.53` stub. birch-cw enables IP forwarding, NAT, and trusts `cni0`.
