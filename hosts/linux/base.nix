# Headless-safe NixOS baseline shared by all Linux hosts.
# Desktop hosts import this via common.nix; servers via server-common.nix.
{ config, pkgs, inputs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable passwordless sudo for zspar
  security.sudo.extraRules = [{
    users = [ "zspar" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Host ed25519 key is the sops-nix age identity. Password SSH is off
  # everywhere; local console / SDDM still use the hashed password on
  # enrolled hosts (see sops.nix).
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Define a user account. Enrolled hosts (meta.sops or true) set
  # hashedPasswordFile from secrets/common.yaml; others stay SSH-key only.
  # Hosts can extend extraGroups (lists merge across modules).
  users.users.zspar = {
    isNormalUser = true;
    description = "Zachary Spar";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Virtualization
  virtualisation.docker.enable = true;

  # Enable Tailscale for remote access
  services.tailscale.enable = true;
}
