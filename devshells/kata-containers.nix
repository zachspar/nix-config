# Dev shell for building Kata Containers (and its kernel).
# Enter with: nix develop .#kata-containers
{ pkgs }:

pkgs.mkShell {
  name = "kata-containers";

  packages = with pkgs; [
    bc
    bison
    coreutils
    flex
    gcc
    gnumake
    pahole
    pkg-config
  ];

  buildInputs = with pkgs; [
    elfutils.dev
    libelf
    openssl.dev
    zlib.dev
  ];

  shellHook = ''
    echo "kata-containers build shell"
  '';
}
