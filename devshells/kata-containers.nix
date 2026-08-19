# Dev shell for building Kata Containers and running a local Kata + containerd
# install from the GitHub static release.
# Enter with: nix develop .#kata-containers
#             nix develop /etc/nixos#kata-containers
{ pkgs }:

let
  inherit (pkgs) lib;

  kataRuntimeInputs =
    with pkgs;
    [
      bash
      coreutils
      curl
      gnutar
      gnused
      gnugrep
      gawk
      jq
      xz
      zstd
      gzip
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      containerd
      nerdctl
      iptables
      iproute2
    ];

  kataSrc = ../scripts/kata;

  wrapKata =
    name: subcommand:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = kataRuntimeInputs;
      text = ''
        exec bash ${kataSrc}/kata.sh ${subcommand} "$@"
      '';
    };

  kata-install = wrapKata "kata-install" "install";
  kata-cleanup = wrapKata "kata-cleanup" "cleanup";
  kata-status = wrapKata "kata-status" "status";
  kata-ubuntu = wrapKata "kata-ubuntu" "ubuntu";
in
pkgs.mkShell {
  name = "kata-containers";

  packages =
    with pkgs;
    [
      bc
      bison
      coreutils
      flex
      gcc
      gnumake
      pahole
      pkg-config
      kata-install
      kata-cleanup
      kata-status
      kata-ubuntu
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      containerd
      nerdctl
    ];

  buildInputs = with pkgs; [
    elfutils.dev
    libelf
    openssl.dev
    zlib.dev
  ];

  shellHook = ''
    export PATH="/opt/kata/bin:$PATH"
    echo "kata-containers build + runtime shell"
    echo "  kata-install [-y] [VERSION]   install Kata 4.0.0 + CNI plugins (/opt/cni/bin)"
    echo "  kata-ubuntu [--keep]          Ubuntu shell via the Kata containerd runtime"
    echo "  kata-status                   show install / containerd / kvm"
    echo "  kata-cleanup                  remove leftover containers, /opt/kata, /opt/cni"
    echo "  NixOS: programs.nix-ld + containerd NIX_LD* (see birch-cw) then rebuild"
    echo ""
  '';
}
