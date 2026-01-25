{ config, pkgs, ... }:

{
  # evdi kernel module (required for Wayland/DisplayLink)
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.evdi ];
    initrd = {
      kernelModules = [ "evdi" ];
    };
  };

  # KDE Plasma Wayland configuration for DisplayLink
  environment.variables = {
    KWIN_DRM_PREFER_COLOR_DEPTH = "24";
  };

  # Ensure Wayland session is properly enabled for DisplayLink
  services = {
    displayManager = {
      sddm = {
        wayland.enable = true;
      };
      defaultSession = "plasma";
    };
  };

  # Install DisplayLink package
  environment.systemPackages = with pkgs; [
    displaylink
  ];

  # Script to prefetch DisplayLink driver (run once manually if needed)
  # Located at: ./prefetch-displaylink.sh

  # Automatically prefetch DisplayLink driver on first boot
  # This runs once to add the driver binary to the nix store
  # The prefetch command is idempotent - it will skip if already present
  systemd.services.prefetch-displaylink = {
    enable = true;
    description = "Prefetch DisplayLink driver for NixOS";
    wantedBy = [ "multi-user.target" ];
    before = [ "displaylink-server.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "prefetch-displaylink" ''
        set -euo pipefail
        DISPLAYLINK_URL="https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip"
        DISPLAYLINK_NAME="displaylink-620.zip"
        
        echo "Prefetching DisplayLink driver..."
        ${pkgs.nix}/bin/nix-prefetch-url --name "$DISPLAYLINK_NAME" "$DISPLAYLINK_URL" || {
          echo "Note: Driver may already be prefetched or prefetch failed. Continuing..."
        }
      '';
      User = "root";
    };
  };

  # DisplayLink server systemd service for KDE Plasma
  # This is the crucial part for enabling the service
  systemd.services.displaylink-server = {
    enable = true;
    # Ensure it starts after udev has done its work and after prefetch
    requires = [ "systemd-udevd.service" "prefetch-displaylink.service" ];
    after = [ "systemd-udevd.service" "prefetch-displaylink.service" ];
    wantedBy = [ "multi-user.target" ]; # Start at boot
    serviceConfig = {
      Type = "simple";
      # The ExecStart path points to the DisplayLinkManager binary provided by the package
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      User = "root";
      Group = "root";
      Restart = "on-failure";
      RestartSec = 5; # Wait 5 seconds before restarting
    };
  };
}

