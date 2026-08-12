# Shared NixOS baseline for headless (server) Linux hosts.
# Provisioned with nixos-anywhere; managed via nixos-rebuild --target-host.
{ config, lib, pkgs, inputs, ... }:

let
  # Personal key used for provisioning and remote management.
  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK37cMZSZZKhgPs/kMnscH3ks5rvoeu4J++J74xAekpa zspar@neo.local"
  ];
in
{
  imports = [ ./base.nix ];

  # Servers use grub with the hybrid disko layout so the same config boots on
  # both BIOS and UEFI firmware (base.nix's systemd-boot is UEFI-only).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # install to EFI/BOOT/BOOTX64.EFI, no NVRAM writes
    # BIOS install devices come from disko (the EF02 partition's disk).
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.zspar.openssh.authorizedKeys.keys = sshAuthorizedKeys;

  # Root key keeps nixos-anywhere and `nixos-rebuild --target-host root@…`
  # friction-free; day-to-day access goes through zspar + passwordless sudo.
  users.users.root.openssh.authorizedKeys.keys = sshAuthorizedKeys;
}
