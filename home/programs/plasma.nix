# KDE Plasma Configurations
{ ... }:

{
  programs.plasma = {
    enable = true;
    overrideConfig = true;

    workspace = {
      colorScheme = "BreezeDark";
      theme = "breeze-dark";
      lookAndFeel = "org.kde.breezedark.desktop";
    };

    shortcuts = {
      kwin = {
        "Window Close" = "Alt+Q";
        "Window Minimize" = "Alt+D";
        "Window Maximize" = "Alt+W";
      };
    };
  };
}
