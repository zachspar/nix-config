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

    # Go uses `git clone https://github.com/...` for modules; private repos need auth.
    # With GOPRIVATE=github.com/builderhub/*, rewriting to SSH uses your normal GitHub SSH key
    # (ssh-agent / 1Password / etc.) instead of ~/.netrc for HTTPS.
    extraConfig = {
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };
}
