# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Behavior Guidline

Behavioral guidelines to reduce common LLM coding mistakes.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.


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
  flake.modules.home."category/name" = { ... };
  flake.modules.homeNixOS."category/name" = { ... };
  flake.modules.homeDarwin."category/name" = { ... };
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

  flake.modules.home."hosts/my-host" = { ... }: {
    # home manager config - receives `userVars` from host.user
  };
};
```

### Host Builders (`modules/flake/`)

- `hosts.nix` - Defines `hosts.nixos` and `hosts.darwin` options, plus the typed `user` submodule schema
- `nixos-configurations.nix` - Thin wrapper calling `mkHostConfigurations` with NixOS-specific params
- `darwin-configurations.nix` - Thin wrapper calling `mkHostConfigurations` with Darwin-specific params
- `lib.nix` - `resolveModules` for module name resolution and `mkHostConfigurations` shared builder

Module name resolution (in `resolveModules`):
- **Exact match**: `"core/nix"` → loads that specific module
- **Prefix match**: `"core"` → loads all modules under `core/`
- **No match**: emits a `builtins.trace` warning and returns `[ ]`

### Host Options

Inside each NixOS/Darwin system, these options are available:
- `host.user` - Typed submodule (name, email, trusted, sshPubKey, shell, homeStateVersion, extraGroups, passwordSecret)
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
5. **Cross-Platform Modules**: Single file can define modules for multiple platforms (nixos/darwin/home/homeNixOS/homeDarwin)

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
   - Add `flake.modules.home."hosts/<hostname>"` for home config
2. For complex hosts, split into multiple files (hardware.nix, packages.nix, etc.)
3. Add secrets to `secrets/` and register in `secrets/secrets.nix`
4. Test with `just build-nixos <hostname>` or `just build-darwin <hostname>`

### Adding a New Module

1. Create `.nix` file in appropriate `modules/` subdirectory
2. Register with the appropriate `flake.modules` namespace:
   - `flake.modules.nixos` - NixOS system modules
   - `flake.modules.darwin` - Darwin system modules
   - `flake.modules.home` - Home Manager modules (shared between NixOS and Darwin)
   - `flake.modules.homeNixOS` - Home Manager modules (NixOS only)
   - `flake.modules.homeDarwin` - Home Manager modules (Darwin only)
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
- Home directory base is `/Users` instead of `/home`

### Checking Temporary Overlay Fixes

Use the repo-local nixpkgs PR/channel helper before removing upstream
workarounds from `modules/overlays/default.nix`:

```bash
# Check PR markers found in the overlay against nixos-unstable.
scripts/check-nixpkgs-pr-channel.py --overlay

# Check a specific PR or a different channel/branch.
scripts/check-nixpkgs-pr-channel.py 536365 -t nixpkgs-unstable
```

Only PR-backed overlay workarounds should be tagged for automatic scanning:

```nix
# pr-tracker: nixpkgs#536365 target=nixos-unstable package=moonlight-qt
```

Keep issue links and non-PR context as normal comments so `--overlay` does not
mistake them for channel-tracked PRs.

When adding a temporary overlay fixup:

1. Keep the patch scoped to the affected package in `modules/overlays/default.nix`.
2. Put the `pr-tracker:` marker directly above the overlay entry it governs.
3. Include `target=<channel>` for the channel that makes the fix removable and
   `package=<attr>` for the local package attr being patched.
4. If the workaround tracks an issue rather than a merged PR, do not add a
   `pr-tracker:` marker; keep the issue link in a normal comment.
5. Run `scripts/check-nixpkgs-pr-channel.py --overlay` before removing any
   marked fixup.

The helper follows pr-tracker's branch propagation rules and exits nonzero when
a checked PR is not yet usable in the requested target.
