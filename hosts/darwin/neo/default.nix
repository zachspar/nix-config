# macOS (neo) system configuration — aarch64-darwin
{ config, pkgs, inputs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "neo";

  nixpkgs.config.allowUnfree = true;

  # Use Determinate’s Nix; don’t let nix-darwin manage Nix (avoids daemon conflict)
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    git
    vim
    ghostty-bin
  ];

  users.users.zspar = {
    name = "zspar";
    description = "Zachary Spar";
    home = "/Users/zspar";
    shell = "/bin/bash";
  };

  system.stateVersion = 4;
}
