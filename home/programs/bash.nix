# Bash configuration
{ pkgs, ... }:

{
  programs.bash = {
    enable = true;

    shellAliases = {
      # ls aliases
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";

      # sudo aliases
      spk = "sudo pkill";
      s = "sudo ";
      svim = "sudo vim ";

      # git
      g = "git";
      gd = "git diff";
      gl = "git log";
      gs = "git status";
      gc = "git commit -m";
      gch = "git checkout";
      gb = "git branch";

      # IP
      wanip = "dig @resolver4.opendns.com myip.opendns.com +short";
      wanip4 = "curl -s http://whatismyip.akamai.com/ && echo";

      diff = "colordiff ";

      # kubectl aliases
      k = "kubectl";
      kaf = "kubectl apply -f";
      kk = "kubectl krew";
      kgp = "kubectl get pods";
      kgn = "kubectl get nodes";
      kdns = "kubectl describe namespace";
      kgcm = "kubectl get configmaps";
    };

    initExtra = ''
      PS1='\[\033[01;36m\][\[\033[01;35m\]\u\[\033[00m\]@\[\033[01;33m\]\h\[\033[01;31m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;36m\]]\[\033[00m\]\$ '
    '';
  };
}
