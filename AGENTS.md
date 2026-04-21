# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS and macOS configuration repository using Nix Flakes with `flake-parts` for modularity and `home-manager` for user-level configurations. Uses `import-tree` for automatic module discovery.

Key features:
- **Secrets management** via `agenix` (encrypted secrets for passwords, API keys)
- **Disk management** via `disko` (declarative partitioning)
- **Secure boot** via `lanzaboote` (NixOS only)
- **Custom overlays** (e.g., `retedo-mono` font, `llm-agents` overlay)

## Core Architecture

### Flake Structure

**`flake.nix`** - Main flake file:
- Defines all inputs (nixpkgs, flake-parts, home-manager, nix-darwin, etc.)
- Uses `import-tree` to auto-load all modules from `./modules`

**`modules/`** - All modules loaded via `import-tree`:
- `modules/flake/` - flake-parts configuration, library functions, and host builders
- `modules/hosts/` - Host-specific configurations
- `modules/core/`, `modules/system/`, etc. - Shared modules by function

### Module System

Modules live in `modules/` organized by function. Each module registers itself in `flake.modules`:

```nix
{ ... }:
{
  flake.modules.nixos."category/name" = { ... };
  flake.modules.darwin."category/name" = { ... };
  flake.modules.homeManager."category/name" = { ... };
}
```

A single file can define modules for multiple platforms (see `modules/core/nix.nix` for example).

Module loading uses `import-tree` which auto-imports all `.nix` files from `modules/` subdirectories.

### Host Definitions

Hosts are defined in `modules/hosts/<hostname>/default.nix` using the `hosts` namespace:

```nix
{ inputs, ... }:
{
  # Host definition
  hosts.nixos.my-host = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/my-host"
      "hardware/nvidia"
    ];
    user = {
      name = "username";
      email = "user@example.com";
      trusted = true;
      sshPubKey = [ "ssh-ed25519 ..." ];
      shell = "fish";
      homeStateVersion = "25.11";
      extraGroups = [ "networkmanager" ];
      passwordSecret = "username-password.age";
    };
    hostPlatform = "x86_64-linux";  # or "aarch64-darwin" for macOS
    stateVersion = "25.05";         # NixOS: "25.05", Darwin: integer (e.g., 6)
  };

  # NixOS modules for this host
  flake.modules.nixos."hosts/my-host" = { pkgs, lib, config, ... }: {
    # hardware config, packages, services, etc.
  };

  flake.modules.homeManager."hosts/my-host" = { ... }: {
    # home manager config - receives `userVars` from host.user
  };
};
```

### Host Builders (`modules/flake/`)

- `hosts.nix` - Defines `hosts.nixos` and `hosts.darwin` options
- `nixos-configurations.nix` - Builds `flake.nixosConfigurations` from `hosts.nixos`
- `darwin-configurations.nix` - Builds `flake.darwinConfigurations` from `hosts.darwin`
- `lib.nix` - `resolveModules` function for module name resolution

Module name resolution:
- **Exact match**: `"core/nix"` → loads that specific module
- **Prefix match**: `"core"` → loads all modules under `core/`

### Host Options

Inside each NixOS/Darwin system, these options are available:
- `host.user` - User configuration from host definition
- `host.hostname` - Hostname (defaults to hosts key name)

Home Manager modules receive `userVars` containing the user config from `host.user`.

### Overlays (`modules/overlays/`)

Custom overlays are defined in `modules/overlays/default.nix`:
- `retedo-mono` - Custom monospace font (based on Iosevka)
- `llm-agents` - AI tools overlay from `numtide/llm-agents.nix`

## Common Commands (Justfile)

The `nh` tool is used for most operations. Set `NH_FLAKE` to point to this repo:

```bash
just                          # List all commands
just switch-nixos             # Build and switch NixOS (current host)
just switch-nixos <hostname>  # Build and switch NixOS (specific host)
just build-nixos              # Build without switching
just switch-darwin            # Build and switch Darwin
just build-darwin             # Build Darwin without switching
just up                       # Update all flake inputs
just up-input <input>         # Update specific flake input
just clean                    # Garbage collect (keep 3 generations)
just edit-secret <path>       # Edit agenix secret (e.g., secrets/api-key.age)
just edit-password <path>     # Edit agenix password secret (auto-hashes with sha-512)
just install-nixos <host> <ip> # Install NixOS via nix-anywhere
just fmt                      # Format all Nix files
just check                    # Check flake outputs
just check-all                # Check flake outputs for all systems
just generations              # List NixOS generations
just history                  # View nix-switch history (OS-aware)
just gcroot                   # List garbage collection roots

# Raw nix commands (fallback if nh unavailable)
just nix-build-nixos          # Raw nix build for NixOS
just nix-switch-nixos         # Raw nixos-rebuild switch
just nix-build-darwin         # Raw nix build for Darwin
just nix-switch-darwin        # Raw darwin-rebuild switch
```

## Key Conventions

1. **Functional Organization**: Modules grouped by function, not platform
2. **Host Colocation**: Host definition and modules in same `modules/hosts/<hostname>/` directory
3. **Prefix Expansion**: Use short prefixes (`"core"`) instead of listing submodules
4. **Secrets**: Store in `secrets/`, reference via `passwordSecret`, edit with `just edit-password`
5. **Cross-Platform Modules**: Single file can define modules for multiple platforms (nixos/darwin/homeManager)

## Directory Structure

```
modules/
├── flake/              # flake-parts config and host builders
│   ├── default.nix     # flake-parts entry point
│   ├── lib.nix         # Library functions (resolveModules)
│   ├── hosts.nix       # hosts.nixos/darwin options
│   ├── nixos-configurations.nix
│   ├── darwin-configurations.nix
│   └── dev-shell.nix   # Development shell
├── hosts/              # Host-specific configurations
│   ├── desktop-home-saki/
│   │   └── default.nix + hardware.nix, filesystem.nix, lanzaboote.nix, etc.
│   ├── laptop-solar-chiyoko/
│   └── laptop-solar-modoka/   # Darwin (macOS) host
├── overlays/           # Custom package overlays
├── core/               # Core system modules (nix, ssh, users, editors, shell)
├── system/             # System configuration
├── desktop/            # Desktop environment (fonts, plasma)
├── apps/               # Applications (ghostty, kitty, mpv, vscode, fcitx5)
├── network/            # Network configuration
├── development/        # Development tools
├── hardware/           # Hardware-specific config (nvidia, fwupd, smartd)

secrets/                # Agenix encrypted secrets
└── secrets.nix         # Public keys mapping for each secret

packages/               # Custom package definitions
├── retedo-mono/        # Custom monospace font (based on Iosevka)
└── ticktick/           # TickTick app with macOS support
```

## Development Workflow

### Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix`:
   - Add `hosts.nixos.<hostname>` or `hosts.darwin.<hostname>` definition
   - Add `flake.modules.nixos."hosts/<hostname>"` for system config
   - Add `flake.modules.homeManager."hosts/<hostname>"` for home config
2. For complex hosts, split into multiple files (hardware.nix, packages.nix, etc.)
3. Add secrets to `secrets/` and register in `secrets/secrets.nix`
4. Test with `just build-nixos <hostname>` or `just build-darwin <hostname>`

### Adding a New Module

1. Create `.nix` file in appropriate `modules/` subdirectory
2. Register with the appropriate `flake.modules` namespace:
   - `flake.modules.nixos` - NixOS system modules
   - `flake.modules.darwin` - Darwin system modules
   - `flake.modules.homeManager` - Home Manager modules
3. Reference in host configs by key or prefix

### Editing Secrets

```bash
# Edit any secret file (opens in editor)
just edit-secret secrets/deepseek-api-key.age

# Edit password secret (automatically hashes with sha-512, strips newlines)
just edit-password secrets/tendo-password.age
```

### Darwin (macOS) Specifics

- `stateVersion` is an integer (e.g., 6), not a string
- `hostPlatform` is `aarch64-darwin` for Apple Silicon
- Homebrew integration available via `homebrew` option in darwin modules
- Home directory base is `/Users` instead of `/home`