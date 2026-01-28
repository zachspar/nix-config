# Linux-specific home-manager configuration
{ pkgs, ... }:

{
  imports = [
    ./common.nix
    ./programs/plasma.nix
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

  # Linux-specific bash aliases
  programs.bash.shellAliases = {
    # systemctl
    ss = "sudo systemctl";
    ssr = "sudo systemctl restart";
    "ss-reboot" = "sudo systemctl reboot";
    sss = "sudo systemctl status";

    # NixOS rebuild
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#maple";
  };
}
