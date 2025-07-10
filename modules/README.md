# Configuration Modules

This directory contains reusable Nix modules organized by target system and configuration scope. Modules are automatically discovered using the `helpers.scanPaths` function, which imports all `.nix` files in a directory.

## Directory Structure

- **`darwin/`** – macOS (Darwin) system configuration
- **`home/`** – User‑level configuration (home‑manager)
- **`nixos/`** – NixOS system configuration

Each subdirectory contains a `default.nix` that uses `helpers.scanPaths ./.;` to import all `.nix` files in that directory. This allows a clean, file‑based organization where each file corresponds to a logical configuration unit.

## Darwin Modules (`darwin/`)

Modules that configure macOS‑specific system settings and preferences.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `system-settings.nix` | macOS system defaults (Dock, Finder, Trackpad, keyboard, etc.) |
| `user-settings.nix` | User‑specific Darwin settings |
| `homebrew-mirror.nix` | Homebrew mirror configuration for China |
| `fonts.nix` | Font configuration |
| `nix.nix` | Nix‑specific settings for Darwin |
| `utility.nix` | Miscellaneous utilities |

## Home Manager Modules (`home/`)

User‑level configurations managed by home‑manager. These modules are imported by host‑specific `home‑<username>.nix` files.

### Development (`development/`)

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `git.nix` | Git configuration |
| `langs/` | Language‑specific toolchains and settings |
| &emsp;`default.nix` | Imports all language modules |
| &emsp;`cpp.nix` | C/C++ development environment |
| &emsp;`python.nix` | Python environment |
| &emsp;`rust.nix` | Rust toolchain |
| &emsp;`nix.nix` | Nix language tooling |
| &emsp;`nodejs.nix` | Node.js/npm/pnpm |
| &emsp;`latex.nix` | LaTeX environment |
| &emsp;`ansible.nix` | Ansible configuration |
| &emsp;`typst.nix` | Typst typesetting system |

### Shell (`shell/`)

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `shell.nix` | General shell configuration |
| `tools.nix` | Shell utilities and tools |
| `neovim.nix` | Neovim editor setup |
| `helix.nix` | Helix editor setup |
| `ssh.nix` | SSH configuration |
| `yazi.nix` | Yazi file manager |

### XDG (`xdg/`)

XDG‑based application configurations.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `base.nix` | Base XDG configuration |
| `dropbox.nix` | Dropbox integration |
| `fcitx5.nix` | Fcitx5 input method |
| `ghostty.nix` | Ghostty terminal configuration |
| `kitty.nix` | Kitty terminal configuration |
| `mpv/` | MPV media player configuration |
| `vscode.nix` | Visual Studio Code settings |

### Miscellaneous

| File | Purpose |
|------|---------|
| `wine.nix` | Wine configuration |

## NixOS Modules (`nixos/`)

System‑level configurations for NixOS. See also the [nixos/README.md](nixos/README.md) for a high‑level overview.

### Base (`base/`)

Core system configuration.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `base-tools.nix` | Essential system packages and basic settings (time zone, locale, etc.) |
| `nix.nix` | Nix‑specific system settings |
| `systemd.nix` | Systemd configuration |
| `user-group.nix` | User and group management |

### Desktop (`desktop/`)

Desktop environment configurations.

| File | Purpose |
|------|---------|
| `default.nix` | Imports `base.nix`, `gnome.nix`, `plasma.nix` |
| `base.nix` | Common desktop utilities |
| `gnome.nix` | GNOME desktop environment |
| `plasma.nix` | KDE Plasma desktop environment |

### Hardware (`hardware/`)

Hardware‑specific modules.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `nvidia.nix` | NVIDIA GPU drivers and settings |
| `smartd.nix` | SMART disk monitoring |

### Networking (`networking/`)

Network configuration and services.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `base.nix` | Basic network configuration |
| `tailscale.nix` | Tailscale VPN |
| `tproxy.nix` | Transparent proxy settings |
| `dae/` | DAE (A high‑performance transparent proxy solution) |
| &emsp;`default.nix` | DAE service configuration |
| &emsp;`config.dae` | DAE configuration file |
| &emsp;`dns.dae` | DAE DNS configuration |

### Utility (`utility/`)

Various system utilities and services.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `boot.nix` | Boot loader configuration |
| `container.nix` | System container support |
| `locale-zh.nix` | Chinese locale settings |
| `sshd.nix` | SSH daemon configuration |
| `sudo.nix` | Sudo configuration |
| `zram.nix` | ZRAM swap space |
| `binbash.nix` | `/bin/bash` compatibility |
| `disable-sleep.nix` | Disable system sleep |

### XDG (`xdg/`)

System‑wide XDG configurations.

| File | Purpose |
|------|---------|
| `default.nix` | Imports all `.nix` files in this directory |
| `appimage.nix` | AppImage support |
| `fonts.nix` | System font configuration |
| `gaming.nix` | Gaming‑related packages and settings |
| `firefox/` | Firefox browser configuration |

## Usage

### Importing Modules in Host Configurations

**System configuration** (`hosts/<hostname>/system.nix`):
```nix
{ ... }:
{
  imports = [
    # Import entire category
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    # Or import individual modules
    ../../modules/nixos/utility/zram.nix
  ];
}
```

**User configuration** (`hosts/<hostname>/home-<username>.nix`):
```nix
{ ... }:
{
  imports = [
    ../../modules/home/development
    ../../modules/home/shell
    ../../modules/home/xdg
  ];
}
```

### Automatic Scanning

Each directory's `default.nix` uses `helpers.scanPaths ./.` to automatically import all `.nix` files in that directory. This means:

- Adding a new `.nix` file to a scanned directory automatically includes it.
- The file name becomes the module name (without the `.nix` extension).
- Subdirectories are **not** automatically scanned unless they contain their own `default.nix` with `scanPaths`.

## Adding New Modules

1. Choose the appropriate category (`darwin/`, `home/`, `nixos/`).
2. Place your `.nix` file in the relevant subdirectory.
3. Ensure the parent directory has a `default.nix` that calls `helpers.scanPaths ./.` (most already do).
4. The module will be automatically available to any host that imports that category.

## Notes

- The `nixos/` directory has its own [README.md](nixos/README.md) with additional guidance.
- Module dependencies are handled through Nix's module system; use `lib.mkDefault`, `lib.mkIf`, etc., to make configurations conditional.
- User‑specific overrides can be applied in host‑specific `home‑<username>.nix` files.