# bootstrap — generic headless install target for nixos-anywhere.
# Install with:  bootstrap-host bootstrap root@<ip>
# Then scaffold a real host (add-host --server <name>) and re-deploy.
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../server-common.nix
    ../disko/single-disk-ext4.nix
  ];

  networking.hostName = lib.mkDefault "bootstrap";

  # Broad driver set so this boots on common VMs and hardware without a
  # generated hardware-configuration.nix.
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "xhci_pci"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
    "usb_storage"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
