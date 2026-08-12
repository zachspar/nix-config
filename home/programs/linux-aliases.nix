# Bash aliases shared by all Linux hosts (desktop and headless).
{ ... }:

{
  programs.bash.shellAliases = {
    # systemctl
    ss = "sudo systemctl";
    ssr = "sudo systemctl restart";
    "ss-reboot" = "sudo systemctl reboot";
    sss = "sudo systemctl status";

    # NixOS rebuild
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
  };
}
