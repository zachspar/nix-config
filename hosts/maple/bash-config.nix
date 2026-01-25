{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = import ./bash-aliases.nix;
    initExtra = ''
      PS1='\[\033[01;36m\][\[\033[01;35m\]\u\[\033[00m\]@\[\033[01;33m\]\h\[\033[01;31m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;36m\]]\[\033[00m\]\$ '
    '';
  };
}

