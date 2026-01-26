# Readline configuration
{ pkgs, ... }:

{
  programs.readline = {
    enable = true;
    includeSystemConfig = true;
    extraConfig = ''
      set completion-ignore-case on
      set show-all-if-ambiguous on
    '';
  };
}
