# Bash configuration
{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

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
      # Source home-manager session vars so sessionPath etc. are available
      # even in non-login shells. We try the nix-darwin per-user location first
      # (what this system actually uses), then fall back to the generic one.
      for hm_vars in \
        "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" \
        "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" \
        "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      do
        if [[ -f "$hm_vars" ]]; then
          . "$hm_vars"
          break
        fi
      done

      # Make ~/.grok/bin available in *every* interactive bash session.
      # We do a direct export (with proper dedup) because the hm-session-vars
      # sourcing is frequently skipped on macOS due to the __HM_SESS_VARS_SOURCED
      # guard when you run `bash` inside an existing terminal session.
      case ":$PATH:" in
        *":$HOME/.grok/bin:"*) ;;
        *) export PATH="$HOME/.grok/bin''${PATH:+:$PATH}" ;;
      esac

      # Change PS1
      PS1='\[\033[01;36m\][\[\033[01;35m\]\u\[\033[00m\]@\[\033[01;33m\]\h\[\033[01;31m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;36m\]]\[\033[00m\]\$ '

      # kubectl completion (if kubectl exists)
      if command -v kubectl &> /dev/null && [[ -n "$BASH_VERSION" ]]; then
        source <(kubectl completion bash 2>/dev/null) || true
        complete -o default -F __start_kubectl k 2>/dev/null || true
      fi

      # Git completion for aliases (only if __git_complete exists)
      if type -t __git_complete &> /dev/null; then
        __git_complete g __git_main
        __git_complete gd _git_diff
        __git_complete gl _git_log
        __git_complete gs _git_status
        __git_complete gc _git_commit
        __git_complete gch _git_checkout
        __git_complete gb _git_branch
      fi
    '';
  };
}
