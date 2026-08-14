# Adding secrets

Secrets live in this public repo as ordinary YAML. Values are age-encrypted (`ENC[...]`); key names stay visible. [sops-nix](https://github.com/Mic92/sops-nix) decrypts them at **activation** on enrolled hosts. Evaluation and CI do not need a private key.

Edit secrets only on neo, with the admin age key:

```
~/.config/sops/age/keys.txt
```

Never commit that file. Machines decrypt with `/etc/ssh/ssh_host_ed25519_key`.

## Tools

```bash
cd ~/Code/nix-config
nix develop
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```

`sops`, `age`, `ssh-to-age`, and `mkpasswd` are on the devshell PATH.

## Add a secret to `secrets/common.yaml`

1. Open the encrypted file (sops decrypts into `$EDITOR` and re-encrypts on save):

   ```bash
   sops secrets/common.yaml
   ```

2. Add a key. Nested keys become path-style names in Nix (`users/zspar/hashedPassword`):

   ```yaml
   users:
     zspar:
       hashedPassword: $y$j9T$…
   someService:
     apiToken: …
   ```

   Values must be strings. Use `mkpasswd -m yescrypt` for login password hashes — NixOS `hashedPasswordFile` will not accept a plaintext password.

3. Confirm it decrypts, then stage it so the flake can see the file:

   ```bash
   sops -d secrets/common.yaml
   git add secrets/common.yaml
   ```

A key that exists only in the YAML is not deployed. Declare it in Nix next.

## Declare it in Nix

Shared secrets for enrolled hosts go in `hosts/linux/sops.nix`. The YAML path is the `sops.secrets` name:

```nix
sops.secrets."someService/apiToken" = { };
```

Use the decrypted path at runtime, never at evaluation:

```nix
services.example.tokenFile = config.sops.secrets."someService/apiToken".path;
```

That file is `/run/secrets/someService/apiToken` after activation.

### Login passwords

User creation runs **before** normal secrets are decrypted. Password hashes need `neededForUsers` so they land in `/run/secrets-for-users/` instead:

```nix
sops.secrets."users/zspar/hashedPassword" = {
  neededForUsers = true;
};

users.mutableUsers = false;
users.users.zspar.hashedPasswordFile =
  config.sops.secrets."users/zspar/hashedPassword".path;
```

`users.mutableUsers = false` makes the hash the source of truth; `passwd` will not stick.

### Optional permission bits

```nix
sops.secrets."someService/apiToken" = {
  owner = "example";
  group = "example";
  mode = "0440";
};
```

`neededForUsers` secrets cannot have an owner — users do not exist yet.

## Enroll a host so it can decrypt

A host can decrypt `secrets/common.yaml` only if its age public key is a recipient in `.sops.yaml`. New hosts from `add-host` start with `sops = false` in `meta.nix` and stay SSH-key-only until you enroll them. `bootstrap` stays opted out.

1. Convert the host SSH pubkey:

   ```bash
   ssh zspar@<host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
   ```

2. Add the `age1…` key to `.sops.yaml` — both under `keys:` and in the `secrets/common.yaml` creation rule. Keep a **single** `key_groups` entry (a list of groups is Shamir and breaks sops-nix):

   ```yaml
   keys:
     - &admin  age1…
     - &flakey age1…
     - &maple  age1…
   creation_rules:
     - path_regex: secrets/common\.yaml$
       key_groups:
         - age:
             - *admin
             - *flakey
             - *maple
   ```

3. Re-encrypt the file for the new recipient:

   ```bash
   sops updatekeys secrets/common.yaml
   ```

4. Set `sops = true` in `hosts/linux/<host>/meta.nix`.

5. Stage and deploy (from neo, for a remote Linux host):

   ```bash
   git add .sops.yaml secrets/common.yaml hosts/linux/<host>/meta.nix

   TMPDIR=/tmp nixos-rebuild switch --flake .#<host> --target-host zspar@<host> \
     --use-remote-sudo --build-host zspar@<host>
   ```

After switch, check:

```bash
# regular secret
sudo cat /run/secrets/someService/apiToken

# password hash
sudo cat /run/secrets-for-users/users/zspar/hashedPassword
```

## Adding a new secrets file later

`secrets/common.yaml` is shared by every enrolled host. For a host-only file, add a creation rule that lists `&admin` and that host only, then set `sopsFile` on the secret:

```nix
sops.secrets."onlyOnMaple" = {
  sopsFile = ../../secrets/maple.yaml;
};
```

Do not put a secret in the NixOS config unless that host is a recipient of the file, or activation will fail.

## Checklist

- [ ] Secret added with `sops secrets/common.yaml` (or a new file + creation rule)
- [ ] Value is a string (hash, not plaintext, for passwords)
- [ ] `sops.secrets."<yaml/path>"` declared in Nix; only `.path` is used
- [ ] Every host that imports that secret is a recipient in `.sops.yaml`
- [ ] `sops updatekeys` run after changing recipients
- [ ] `sops = true` in that host’s `meta.nix`
- [ ] Files `git add`ed so the flake can see them
- [ ] `secrets/*.yaml` in git contains only `ENC[...]` values
