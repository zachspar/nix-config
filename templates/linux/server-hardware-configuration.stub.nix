# Generic hardware configuration for host HOSTNAME.
# bootstrap-host replaces this with a generated one during the
# nixos-anywhere install (via --generate-hardware-config); commit the result.
# Until then, a broad driver set keeps the system bootable on common
# VMs and hardware. Filesystems are managed by disko, not this file.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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
}
