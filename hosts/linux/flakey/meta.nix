# Per-host flake metadata (used by auto-discovery in flake.nix).
# headless = true selects the server home-manager profile (no plasma/GUI).
# Host SSH key is already a recipient in .sops.yaml. Flip sops on after
# replacing the placeholder hash in secrets/common.yaml.
{
  system = "x86_64-linux";
  headless = true;
  sops = true;
}
