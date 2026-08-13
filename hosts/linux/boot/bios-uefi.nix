# Firmware-agnostic bootloader: boots on both BIOS and UEFI machines.
# Implemented with grub, paired with the hybrid disko layout (EF02 BIOS boot
# partition + ESP). Overrides base.nix's systemd-boot, which is UEFI-only.
{ lib, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # install to EFI/BOOT/BOOTX64.EFI, no NVRAM writes
    # BIOS install devices come from disko (the EF02 partition's disk).
  };
}
