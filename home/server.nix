# Headless (server) home-manager configuration — no GUI apps, no plasma.
{ pkgs, ... }:

{
  imports = [
    ./common.nix
    ./programs/linux-aliases.nix
  ];
}
