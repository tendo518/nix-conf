# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS and macOS configuration repository using Nix Flakes with `flake-parts` for modularity and `home-manager` for user-level configurations. A custom `mkHost` function handles both NixOS and Darwin systems.

Key features:
- **Secrets management** via `agenix` (encrypted secrets for passwords, API keys)
- **Disk management** via `disko` (declarative partitioning)
- **Secure boot** via `lanzaboote` (NixOS only)
- **Custom overlays** (e.g., `iosevka-lnxw` font)

## Core Architecture

### Flake Structure

**`flake.nix`** - Main flake file:
- Defines all inputs (nixpkgs, flake-parts, home-manager, nix-darwin, etc.)
- Configures `perSystem.devShells.default` with development tools
- Imports modules via `imports` list

**`modules/flake-parts.nix`** - flake-parts module:
- Defines module registry options (`flake.modules.nixos/darwin/homeManager/darwinHomeManager/nixosHomeManager`)
- Island pattern: overrides `perSystem._module.args.pkgs` with overlays + `allowUnfree`
- Exports `flake.lib.mkHost` helper
- Builds `flake.nixosConfigurations` and `flake.darwinConfigurations`

**`modules/default.nix`** - Auto-imports all `.nix` files from `modules/` subdirectories

### Module System

Modules live in `modules/` organized by function (`core`, `system`, `desktop`, etc.). Each module registers itself in `flake.modules`:

```nix
{ ... }:
{
  flake.modules.nixos."category/name" = { ... };
  flake.modules.darwin."category/name" = { ... };
  flake.modules.homeManager."category/name" = { ... };

  # Platform-specific Home Manager modules (optional)
  flake.modules.darwinHomeManager."category/name" = { ... };  # Darwin only
  flake.modules.nixosHomeManager."category/name" = { ... };   # NixOS only
}
```

Module loading uses `modules/default.nix` which auto-imports all `.nix` files from `modules/` subdirectories.

**Platform-specific Home Manager modules:**
- `flake.modules.homeManager` - Shared across all platforms
- `flake.modules.darwinHomeManager` - Loaded only for Darwin hosts
- `flake.modules.nixosHomeManager` - Loaded only for NixOS hosts

This allows conditional loading of platform-specific Home Manager configurations (e.g., `mac-app-util` for Darwin only).

### Host Definition Pattern

Hosts are defined in `hosts/<hostname>/default.nix`. Each host calls `mkHost`:

```nix
{ config, ... }:
{
  flake.modules.nixos."my-host-system" = ./system/default.nix;
  flake.modules.homeManager."my-host-home" = ./home/tendo.nix;

  flake.modules.nixos."nixosConfigurations/my-host" =
    config.flake.lib.mkHost {
      systemType = "nixos";
      users.tendo = {
        email = "user@example.com";
        trusted = true;
        sshPubKey = [ "ssh-ed25519 ..." ];
        shell = "fish";
        homeStateVersion = "25.11";
        extraGroups = [ "networkmanager" ];
        passwordSecret = "tendo-password.age";
      };
      stateVersion = "25.05";
      modules = [
        "my-host-system"
        "my-host-home"
        "core"      # Prefix: loads all core/* modules
        "system"    # Prefix: loads all system/* modules
        "networking"
        "apps"
        "development"
        "desktop"
        "desktop-environments/plasma"
      ];
      inherit config;
    };
}
```

### mkHost Function (`lib/mkHost.nix`)

Wires together:
1. System modules (NixOS or Darwin)
2. Home Manager modules for users (with platform-specific filtering)
3. Agenix for secrets
4. User config from `host.users` options

**Platform-specific Home Manager merging:**
- Darwin hosts: `homeManager` + `darwinHomeManager`
- NixOS hosts: `homeManager` + `nixosHomeManager`

Module name resolution:
- **Exact match**: `"core/nix"` → loads that specific module
- **Prefix match**: `"core"` → loads all modules under `core/`

**Library structure** (`lib/`):
- `platforms.nix` - Platform lookup table (darwin/nixos config prefixes, builders, modules)
- `resolveModules.nix` - Module resolution functions (`resolveModules`, `validateModules`)
- `mkHost.nix` - Host builders (`mkHost`, `mkSystemConfigs`)
- `options.nix` - Host options definitions (`host.users`, `host.hostname`)
- `default.nix` - Main entry point, re-exports all library functions

### User Configuration (`host.users`)

Defined in `lib/options.nix`:

```nix
host.users.tendo = {
  email = "user@example.com";        # Required
  trusted = true;                     # Adds to wheel/admin group
  sshPubKey = [ "ssh-ed25519 ..." ];  # SSH authorized keys
  shell = "fish";                     # Default: "bash"
  homeStateVersion = "25.11";         # Required for Home Manager
  extraGroups = [ "networkmanager" ];
  passwordSecret = "tendo-password.age"; # Agenix secret for hashed password
};
```

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
2. **Cross-Platform Design**: Use separate `nixosModule` and `darwinModule` when options differ
3. **Unified Loading**: `mkHost` handles NixOS/Darwin logic plus Home Manager setup
4. **User Config**: Drives user creation, shell enabling, trusted-user settings
5. **Secrets**: Store in `secrets/`, reference via `passwordSecret`, edit with `just edit-password`
6. **Module Prefix Expansion**: Use short prefixes (`"core"`) instead of listing submodules

## Development Workflow

### Adding a New Host
1. Create `hosts/<hostname>/default.nix` with `mkHost` call
2. Create `hosts/<hostname>/system/default.nix` for hardware/system config
3. Create `hosts/<hostname>/home/<username>.nix` for Home Manager overrides
4. Add secrets to `secrets/` and register in `secrets/secrets.nix`
5. Test with `just build-nixos <hostname>`

### Adding a New Module
1. Create `.nix` file in appropriate `modules/` subdirectory
2. Register with the appropriate flake.modules namespace:
   - `flake.modules.nixos` - NixOS system modules
   - `flake.modules.darwin` - Darwin system modules
   - `flake.modules.homeManager` - Shared Home Manager modules (all platforms)
   - `flake.modules.darwinHomeManager` - Darwin-only Home Manager modules
   - `flake.modules.nixosHomeManager` - NixOS-only Home Manager modules
3. Reference in host configs by key or prefix

### Editing Secrets

```bash
# Edit any secret file (opens in editor)
just edit-secret secrets/deepseek-api-key.age

# Edit password secret (automatically hashes with sha-512, strips newlines)
just edit-password secrets/tendo-password.age
```
