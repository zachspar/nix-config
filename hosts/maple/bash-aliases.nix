# Bash shell aliases
{
  # ls aliases
  ll = "ls -alF";
  la = "ls -A";
  l = "ls -CF";

  # systemctl
  ss = "sudo systemctl";
  ssr = "sudo systemctl restart";
  "ss-reboot" = "sudo systemctl reboot";
  sss = "sudo systemctl status";

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
}
