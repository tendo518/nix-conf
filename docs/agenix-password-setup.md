# Setting Up User Passwords with Agenix

This guide explains how to use [agenix](https://github.com/ryantm/agenix) to manage encrypted user passwords in this flake.

## Prerequisites

- Enter the dev shell: `nix develop` (provides the `age` CLI)
- Have an SSH ed25519 key (`ssh-keygen -t ed25519` if you don't)
- Know each NixOS host's SSH host key

## How It Works

```
secrets/secrets.nix    ← Declares which public keys can decrypt each secret
secrets/<name>.age     ← Encrypted secret files
core/options.nix       ← Defines `host.users.<name>.passwordSecret` option
core/users.nix         ← Wires passwordSecret → age.secrets → hashedPasswordFile
flake-parts/lib.nix    ← Auto-imports agenix NixOS/Darwin modules
```

When `host.users.<name>.passwordSecret = "tendo.age"` is set in a host's `system.nix`, the `core/users.nix` module will:

1. Declare `age.secrets."tendo.age".file` pointing to `secrets/tendo.age`
2. Set `users.users.<name>.hashedPasswordFile` to the decrypted secret path

## Step-by-Step

### 1. Get Host SSH Public Keys

Each NixOS host has an SSH host key that agenix uses for decryption at boot.

```bash
# On the target host, or via SSH:
ssh-keyscan -t ed25519 <host-ip> 2>/dev/null | awk '{print $2 " " $3}'

# Or read directly on the host:
cat /etc/ssh/ssh_host_ed25519_key.pub
```

### 2. Edit `secrets/secrets.nix`

This file declares which public keys can decrypt each `.age` file. List **all keys** that should have access (your user key + relevant host keys):

```nix
let
  # Host SSH public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  laptop-solar-chiyoko = "ssh-ed25519 AAAAC3N...chiyoko-host-key";
  laptop-solar-modoka  = "ssh-ed25519 AAAAC3N...modoka-host-key";

  # User SSH public keys (from ~/.ssh/id_ed25519.pub)
  tendo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR";
in
{
  # Each host that needs this password must have its key listed here
  "tendo.age".publicKeys = [ tendo laptop-solar-chiyoko ];
}
```

> **Important**: Include the host key of every NixOS machine that needs to decrypt the secret at boot. Darwin hosts don't use `hashedPasswordFile`, so they don't need to be listed.

### 3. Create the Encrypted Password File

Generate a hashed password and encrypt it:

```bash
# Generate a hashed password (will prompt for input)
mkpasswd -m sha-512 | age -r "ssh-ed25519 AAAAC3N..." -o secrets/tendo.age

# Or use agenix CLI (reads secrets.nix automatically):
cd secrets/
agenix -e tendo.age
# This opens $EDITOR — paste the hashed password, save, and exit
```

> **Note**: The file must contain a **hashed** password (output of `mkpasswd`), not a plaintext password.

### 4. Set `passwordSecret` in Host Config

In the host's `system.nix`, set the option on the user:

```nix
# hosts/laptop-solar-chiyoko/system.nix
{
  host.users.tendo = {
    email = "pengwyuan@gmail.com";
    trusted = true;
    shell = "fish";
    homeStateVersion = "25.11";
    passwordSecret = "tendo.age";  # ← references secrets/tendo.age
    # ...
  };
}
```

### 5. Build and Deploy

```bash
just switch-nixos   # or: just build-nixos --dry-run
```

On boot, agenix decrypts `tendo.age` using the host's SSH key and places the plaintext at a temporary path, which NixOS uses as the `hashedPasswordFile`.

## Editing an Existing Secret

```bash
cd secrets/
agenix -e tendo.age
# Opens $EDITOR with the decrypted content. Edit, save, exit.
```

## Re-keying After Adding a New Host

If you add a new host key to `secrets.nix`, you must re-encrypt so the new host can decrypt:

```bash
cd secrets/
agenix --rekey
```

This re-encrypts all `.age` files for their updated public key lists.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Build error: `path '.../secrets/tendo.age' does not exist` | Missing encrypted file | Run `agenix -e tendo.age` to create it |
| Login fails after deploy | Wrong hash format | Re-run `mkpasswd -m sha-512` and re-encrypt |
| `age: error: no identity matched` | Host key not in `secrets.nix` | Add host key to `publicKeys`, then `agenix --rekey` |
| Works on host A but not host B | Host B's key not listed | Add host B's key to `publicKeys`, then `agenix --rekey` |
