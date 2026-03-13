# Darwin-specific home-manager configuration (macOS)
{ pkgs, ... }:

{
  imports = [ ./common.nix ];

  # Prefer Nix’s Bash over macOS /bin/bash so `bash` uses a version that supports the generated .bashrc
  home.sessionPath = [ "${pkgs.bash}/bin" ];

  home.packages = with pkgs; [
    # Add darwin-specific packages as needed
  ];

  programs.bash.shellAliases = {
    # nix-darwin rebuild (run from nix-config repo)
    rebuild = "darwin-rebuild switch --flake .#neo";
  };
}
