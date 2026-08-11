# Tumble — desktop workstation
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    # ../programs/displaylink/displaylink.nix
  ];

  boot.initrd.luks.devices."luks-d6368b18-a8ad-448b-a3ae-a118107830af".device = "/dev/disk/by-uuid/d6368b18-a8ad-448b-a3ae-a118107830af";

  networking.hostName = "tumble";

  users.users.zspar = {
    extraGroups = [ "libvirtd" ];
    openssh.authorizedKeys.keys = [
      # GitHub CI/CD pipeline key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiMoJsvyQkzI8RShn+qgcUy/Semp91TiLSaRhdzH/93 github-ci@tumble"
    ];
  };

  # Enable Steam
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";  # Start VMs at boot
    onShutdown = "shutdown";  # Gracefully shutdown VMs
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
