# Per-host flake metadata (used by auto-discovery in flake.nix).
# headless = true selects the server home-manager profile (no plasma/GUI).
# sops = false until the host SSH key is added as a recipient (see README).
{
  system = "SYSTEM";
  headless = true;
  sops = false;
}
