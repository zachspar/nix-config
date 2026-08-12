# Single-disk hybrid GPT layout: BIOS boot partition + 1G ESP + ext4 root.
# Boots on both BIOS and UEFI firmware (grub, see server-common.nix).
# Hosts override the target disk with:
#   disko.devices.disk.main.device = "/dev/nvme0n1";
{ lib, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition (grub stage 1.5)
        };
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
