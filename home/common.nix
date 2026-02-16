# Common home-manager configuration shared across all hosts
{ pkgs, ... }:

{
  # Import program configurations
  imports = [
    ./programs/vim.nix
    ./programs/bash.nix
    ./programs/git.nix
    ./programs/readline.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Common packages installed on all systems
  home.packages = with pkgs; [
    # basics
    ripgrep
    htop
    neofetch
    tree
    jq
    yq
    direnv

    # python
    python3

    # k8s
    kubectl
    kns
    kubelogin-oidc
    kubernetes-helm
    cilium-cli
  ];
}
