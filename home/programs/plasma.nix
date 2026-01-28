# KDE Plasma Configurations
{ ... }:

{
  programs.plasma = {
    enable = true;
    shortcuts = {
      kwin = {
        "Close Window" = "Alt+Q";
      };
    };
  };
}
