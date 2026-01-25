{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = import ./bash-aliases.nix;
  };
}

