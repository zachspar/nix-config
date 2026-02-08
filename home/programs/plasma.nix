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

    # Enable Alt+Mouse click to drag windows
    configFile = {
      kwinrc = {
        Windows = {
          ElectricBorderDelay = 150;
        };
        MouseBindings = {
          CommandAllKey = "Alt";
          CommandWindow1 = "Move";
          CommandWindow2 = "Toggle raise and lower";
          CommandWindow3 = "Resize";
        };
      };
    };
  };
}
