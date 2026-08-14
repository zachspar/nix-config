# Per-host flake metadata (used by auto-discovery in flake.nix).
# sops = false until the host SSH key is added as a recipient (see README).
{
  system = "SYSTEM";
  sops = false;
}
