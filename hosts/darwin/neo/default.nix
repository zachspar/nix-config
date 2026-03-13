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
  ];

  users.users.zspar = {
    name = "zspar";
    description = "Zachary Spar";
    home = "/Users/zspar";
    # Use Nix’s Bash so Home Manager’s .bashrc (Bash 4+ features) works; macOS /bin/bash is 3.2
    shell = "${pkgs.bash}/bin/bash";
  };

  system.stateVersion = 4;
}
