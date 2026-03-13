# Darwin-specific home-manager configuration (macOS)
{ pkgs, ... }:

{
  imports = [ ./common.nix ];

  home.packages = with pkgs; [
    # Add darwin-specific packages as needed
  ];

  programs.bash.shellAliases = {
    # nix-darwin rebuild (run from nix-config repo); activation requires root
    rebuild = "sudo darwin-rebuild switch --flake .#neo";
  };
}
