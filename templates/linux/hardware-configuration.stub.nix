# Stub hardware configuration — replace before switching.
#
# On the target machine, run:
#   nixos-generate-config --show-hardware-config > hosts/linux/HOSTNAME/hardware-configuration.nix
#
# Or from the repo root after cloning onto the machine:
#   nixos-generate-config --show-hardware-config > hosts/linux/HOSTNAME/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Fail evaluation until real hardware config is generated.
  assertions = [
    {
      assertion = false;
      message = ''
        Host HOSTNAME still has a stub hardware-configuration.nix.
        On the target machine run:
          nixos-generate-config --show-hardware-config > hosts/linux/HOSTNAME/hardware-configuration.nix
        Then commit and rebuild.
      '';
    }
  ];
}
