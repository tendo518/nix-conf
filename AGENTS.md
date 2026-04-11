# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS and macOS configuration repository using Nix Flakes with `flake-parts` for modularity and `home-manager` for user-level configurations. Uses `import-tree` for automatic module discovery.

Key features:
- **Secrets management** via `agenix` (encrypted secrets for passwords, API keys)
- **Disk management** via `disko` (declarative partitioning)
- **Secure boot** via `lanzaboote` (NixOS only)
- **Custom overlays** (e.g., `retedo-mono` font)

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
      "networking"
      "desktop"
      "hosts/my-host"
      "desktop-environments/plasma"
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
    stateVersion = "25.05";
  };

  # NixOS modules for this host
  flake.modules.nixos."hosts/my-host" = { pkgs, lib, config, ... }: {
    # hardware config, packages, services, etc.
  };

  flake.modules.homeManager."hosts/my-host" = { ... }: {
    # home manager config
  };
};
```

### Host Builders (`modules/flake/`)

- `hosts.nix` - Defines `hosts.nixos` and `hosts.darwin` options
- `nixos-configurations.nix` - Builds `flake.nixosConfigurations` from `hosts.nixos`
- `darwin-configurations.nix` - Builds `flake.darwinConfigurations` from `hosts.darwin`

Module name resolution:
- **Exact match**: `"core/nix"` → loads that specific module
- **Prefix match**: `"core"` → loads all modules under `core/`

### Host Options

Inside each NixOS/Darwin system, these options are available:
- `host.user` - User configuration from host definition
- `host.hostname` - Hostname (defaults to hosts key name)

## Common Commands (Justfile)

```bash
just                          # List all commands
just switch-nixos             # Build and switch NixOS (current host)
just switch-nixos <hostname>  # Build and switch NixOS (specific host)
just build-nixos              # Build without switching
just switch-darwin            # Build and switch Darwin
just up                       # Update all flake inputs
just up-input <input>         # Update specific flake input
just clean                    # Garbage collect (keep 3 generations)
just edit-secret <path>       # Edit agenix secret (e.g., secrets/api-key.age)
just edit-password <path>     # Edit agenix password secret (auto-hashes with sha-512)
just install-nixos <host> <ip> # Install NixOS via nix-anywhere
just fmt                      # Format all Nix files
just check                    # Check flake outputs
just generations              # List NixOS generations
```

## Key Conventions

1. **Functional Organization**: Modules grouped by function, not platform
2. **Host Colocation**: Host definition and modules in same `modules/hosts/<hostname>/` directory
3. **Prefix Expansion**: Use short prefixes (`"core"`) instead of listing submodules
4. **Secrets**: Store in `secrets/`, reference via `passwordSecret`, edit with `just edit-password`

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
│   │   ├── default.nix     # hosts.nixos + modules
│   │   ├── hardware.nix
│   │   ├── filesystem.nix
│   │   ├── lanzaboote.nix
│   │   ├── nfs.nix
│   │   ├── packages.nix
│   │   └── home.nix
│   ├── laptop-solar-chiyoko/
│   │   └── default.nix
│   └── laptop-solar-modoka/
│       └── default.nix
├── overlays/           # Custom package overlays
├── core/               # Core system modules
├── system/             # System configuration
├── desktop/            # Desktop environment
├── apps/               # Applications
├── networking/         # Network configuration
├── development/        # Development tools
└── hardware/           # Hardware-specific config

packages/               # Custom package definitions
└── retedo-mono/        # Custom monospace font (based on Iosevka)
```

## Development Workflow

### Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix`:
   - Add `hosts.nixos.<hostname>` or `hosts.darwin.<hostname>` definition
   - Add `flake.modules.nixos."hosts/<hostname>"` for system config
   - Add `flake.modules.homeManager."hosts/<hostname>"` for home config
2. For complex hosts, split into multiple files (hardware.nix, packages.nix, etc.)
3. Add secrets to `secrets/` and register in `secrets/secrets.nix`
4. Test with `just build-nixos <hostname>`

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