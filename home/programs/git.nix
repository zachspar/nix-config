# Git configuration
{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Zachary Spar";
    userEmail = "zachspar@gmail.com";
  };
}
