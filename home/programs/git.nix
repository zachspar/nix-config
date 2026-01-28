# Git configuration
{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Zachary Spar";
        email = "zachspar@gmail.com";
      };
      push = { autoSetupRemote = true; };
      pull = { rebase = true; };
    };
  };
}
