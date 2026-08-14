# sops-nix wiring for enrolled Linux hosts (meta.sops or true).
# Decrypts with the SSH host ed25519 key at activation. The committed
# secrets file is age-encrypted; evaluation does not need the private key.
{ config, ... }:

{
  sops.defaultSopsFile = ../../secrets/common.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Available under /run/secrets-for-users/ before users are created.
  sops.secrets."users/zspar/hashedPassword" = {
    neededForUsers = true;
  };

  users.mutableUsers = false;
  users.users.zspar.hashedPasswordFile = config.sops.secrets."users/zspar/hashedPassword".path;
}
