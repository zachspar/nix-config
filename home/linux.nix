# Linux-specific home-manager configuration
{ pkgs, ... }:

{
  imports = [
    ./common.nix
    ./programs/plasma.nix
    ./programs/linux-aliases.nix
  ];

  # Linux-specific packages
  home.packages = with pkgs; [
    # Unfree Linux apps
    code-cursor
    zoom-us
    lens

    # talosctl is Linux-only in nixpkgs
    talosctl
  ];
}
