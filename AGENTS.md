# AGENTS.md

This file provides guidance to AI coding agents working with code in this repository.

## Behavior Guideline

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

Personal NixOS and macOS configuration repository for 5 machines (4 NixOS hosts + 1 macOS) using Nix Flakes with `flake-parts` for modularity and `home-manager` for user-level configurations. Uses `import-tree` for automatic module discovery.

Key features:
- **Secrets management** via `agenix` (encrypted secrets for passwords, API keys)
- **Disk management** via `disko` (declarative partitioning)
- **Secure boot** via `lanzaboote` (NixOS only)
- **Custom overlays** (`llm-agents` AI tools, pinned package builds from `packages/`)
- **LLM agent tooling** via `numtide/llm-agents.nix` (`modules/agents/`: Claude Code, Codex, OpenCode, ...)

## Core Architecture

### Flake Structure

**`flake.nix`** - Main flake file:
- Defines all inputs (nixpkgs, flake-parts, home-manager, nix-darwin, etc.)
- Uses `import-tree` to load flake assembly from `./flake`, host declarations from
  `./hosts`, and selectable configuration modules from `./modules`

**`flake/`** - flake-parts configuration, host builder, overlays, and dev shell.

**`hosts/`** - Host declarations (module selection, user, platform, state version).

**`modules/`** - Selectable configuration modules and their private assets:
- `modules/hosts/` - Host-specific selectable configuration modules
- `modules/core/`, `modules/system/`, etc. - Shared modules by function

**`flake/_lib/`** - Private helpers used only by flake assembly:
- `host-builder.nix` - module-name resolution/validation and `mkHostConfigurations`

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

A single file can define modules for multiple platforms by registering the same
implementation under each applicable `flake.modules` namespace.

`import-tree` auto-imports each of `flake/`, `hosts/`, and `modules/`.  Only
`modules/` contains selectable `flake.modules.*` registrations; a leading
underscore marks a private helper/data path that import-tree ignores.

### Host Definitions

Hosts are declared in `hosts/<hostname>.nix` using the `hosts` namespace. Their
host-specific selectable modules live separately in `modules/hosts/<hostname>/`:

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
    excludeModules = [
      "apps/gaming"
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

};
```

Register the corresponding NixOS/Darwin/Home Manager host modules separately
under `modules/hosts/<hostname>/`.

### Host Builders (`flake/`)

- `host-options.nix` - Defines `hosts.nixos` and `hosts.darwin` options, plus the typed `user` submodule schema
- `nixos-configurations.nix` - Directly exports NixOS configurations from `hosts.nixos`
- `darwin-configurations.nix` - Directly exports Darwin configurations from `hosts.darwin`

Module name resolution (in `flake/_lib/host-builder.nix`):
- **Exact match**: `"core/nix"` → loads that specific module
- **Prefix match**: `"core"` → loads all modules under `core/`; `"hosts/my-host"` loads the host module and its split submodules (hardware, system, ...)
- **Exclusions**: `excludeModules` expand the same way (exact + prefix); results are deduplicated by first occurrence
- **Validation**: included names must exist for the current platform; exclusions may target any registered platform module, while unknown names still throw at eval time

### Host Options

Host/user context is computed before module evaluation and injected via `specialArgs`:
- NixOS/Darwin modules receive `hostContext = { hostname, user }` (e.g. `{ hostContext, ... }:`), where `user` is the typed user config
- Home Manager modules receive both `hostContext` and `userContext` (the user config) via `extraSpecialArgs`

Use `hostContext.user.name` instead of the old `config.host.user.name` path.

### Overlays (`modules/overlays/`)

Custom overlays are defined in `modules/overlays/default.nix` (exposed as `config.flake.overlays`):
- `llm-agents` - AI tools from `numtide/llm-agents.nix`
- `ticktick`, `skimpdf`, `deskflow`, `clash-verge-rev` - pinned local builds from `packages/` (platform guards per package)
- `chatgpt-desktop` - official artifact on macOS; `llm-agents.chatgpt` on Linux

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
2. **Host Split**: Host declarations live in `hosts/`; host-specific selectable modules live in `modules/hosts/<hostname>/`
3. **Prefix Expansion**: Use short prefixes (`"core"`) instead of listing submodules
4. **Secrets**: Store in `secrets/`, reference via `passwordSecret`, edit with `just edit-password`
5. **Cross-Platform Modules**: Single file can define modules for multiple platforms (nixos/darwin/home/homeNixOS/homeDarwin)
6. **Module Boundary**: `modules/` only contains selectable `flake.modules.*` registrations and their private assets; flake assembly lives in `flake/`

## Gotchas / Operational Notes

### disko does not format by itself; nixos-anywhere does

- `disko.devices` only describes the target layout. The `disko` CLI's default
  mode is `mount` (non-destructive); it only wipes when you explicitly run
  `destroy`/`destroy,format,mount`.
- `nixos-anywhere` is a reinstall tool, not an update tool. Its default
  `--disko-mode disko` phase unmounts and destroys the filesystems on the
  configured disks before creating/formatting them again.
- After kexec, the installer is **not** on the tailnet, so `<host>.tailscale`
  becomes unreachable. Do not run nixos-anywhere against a box you cannot
  reach physically/IPMI/LAN — you can strand it in the kexec installer.
- To update an already-running host, use `nixos-rebuild switch --target-host`
  or `nh` instead of nixos-anywhere.

### New files must be `git add`-ed before flake evaluation

- Nix flakes only read git-tracked files. A brand-new module file is invisible
  to `nix flake check` / `nix build` / `import-tree` until it is `git add`-ed,
  so a missing module can look like a silent no-op.
- After adding a new `.nix` module, run `git add <file>` first, then evaluate.
  Modified (already-tracked) files are picked up even when the tree is dirty.

## Directory Structure

```
flake/                  # Flake-parts assembly, outputs, options, and private host builder
├── _lib/host-builder.nix
├── default.nix
├── host-options.nix
├── nixos-configurations.nix
└── darwin-configurations.nix

hosts/                  # Host declarations (selected modules, user, platform, state)

modules/
├── hosts/              # Host-specific selectable configurations
│   ├── desktop-home-saki/    # hardware.nix, system.nix (LUKS, lanzaboote, btrfs)
│   ├── desktop-lab-peace/    # default.nix module + hardware.nix, system.nix
│   ├── laptop-solar-chiyoko/ # hardware.nix, system.nix (aarch64 ThinkPad X13s)
│   ├── laptop-solar-modoka/  # Darwin (macOS) modules
│   └── server-lab-sardine/   # hardware, system, router, and self-hosted services
├── core/               # Core system modules (nix, nixpkgs, ssh, users, editors, shell, xdg)
├── system/             # System configuration
├── desktop/            # Desktop environment (fonts, plasma, input-method, niri)
├── agents/             # LLM agent CLIs (claude-code, codex, hermes, omp, pi, reasonix)
├── apps/               # Applications (ghostty, kitty, mpv, vscode, neovim, yazi, firefox)
├── network/            # Network configuration (tailscale, tailnet, syncthing, tproxy)
├── development/        # Development tools
└── hardware/           # Hardware-specific config (nvidia, fwupd, lenovo-x13s)

secrets/                # Agenix encrypted secrets
└── secrets.nix         # Public keys mapping for each secret

packages/               # Custom package definitions; platform guards per package where needed
├── ticktick/           # TickTick app with macOS support
├── skimpdf/            # Skim PDF with macOS support
├── deskflow/           # Deskflow with macOS support
├── chatgpt-desktop/     # ChatGPT desktop (macOS artifact)
└── clash-verge-rev/    # Clash Verge Rev with macOS support

scripts/                # Helpers (check-nixpkgs-pr-channel.py, update-tailnet-hosts.py)
docs/                   # Runbooks and notes (agenix setup, hardware debugging)
```

## Development Workflow

### Adding a New Host

1. Create `hosts/<hostname>.nix` with the `hosts.nixos.<hostname>` or
   `hosts.darwin.<hostname>` declaration and selected module list.
2. Add `flake.modules.nixos."hosts/<hostname>"` and/or
   `flake.modules.home."hosts/<hostname>"` under `modules/hosts/<hostname>/`.
3. For complex hosts, split selectable configuration into multiple files (hardware.nix, packages.nix, etc.)
4. Add secrets to `secrets/` and register in `secrets/secrets.nix`
5. Test with `just build-nixos <hostname>` or `just build-darwin <hostname>`

### Adding a New Module

1. Create `.nix` file in appropriate `modules/` subdirectory
2. Register with the appropriate `flake.modules` namespace:
   - `flake.modules.nixos` - NixOS system modules
   - `flake.modules.darwin` - Darwin system modules
   - `flake.modules.home` - Home Manager modules (shared between NixOS and Darwin)
   - `flake.modules.homeNixOS` - Home Manager modules (NixOS only)
   - `flake.modules.homeDarwin` - Home Manager modules (Darwin only)
3. Reference in host configs by key or prefix
4. Register the same implementation under multiple namespaces when it applies to
   multiple platforms. Unknown module names fail evaluation, so `just check`
   catches typos instead of silently skipping modules.

### Adding a New Pinned Package

Packages under `packages/` are custom pinned packages and can target one or
more platforms. Platform guards belong in `packages/default.nix` or in the
package derivation itself. Each package has two parts:

- `packages/<name>/default.nix` - the Nix derivation with version/hash metadata
- `packages/<name>/update.sh` - a small script that fetches the latest metadata
  from Homebrew/upstream and rewrites the pinned fields

The shared helpers live in `packages/update-lib.sh`, and the scheduled workflow
discovers update scripts by globbing `packages/*/update.sh`, so adding a new
package does not require editing `.github/workflows/update-packages.yml`.

1. Create `packages/<name>/default.nix` as a normal `callPackage`-compatible
   derivation for the intended platform(s). Keep the fields the updater needs
   as simple literal bindings: `version`, `hash` or
   `armHash`/`intelHash`, and any optional `url`/token fields. Use `fetchurl`
   for the artifact.

2. Create executable `packages/<name>/update.sh`. Source the shared helpers,
   fetch the newest metadata, then rewrite the matching fields:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/../update-lib.sh"

   NIX_FILE="$SCRIPT_DIR/default.nix"

   # Fetch from Homebrew API, a cask file, GitHub releases, etc.
   JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/<name>.json')

   VERSION=$(echo "$JSON" | jq -r '.version')
   SHA_HEX=$(echo "$JSON" | jq -r '.sha256')
   HASH=$(to_sri "$SHA_HEX")

   sed_inplace "$NIX_FILE" \
     -e "s|version = \".*\";|version = \"$VERSION\";|" \
     -e "s|hash = \".*\";|hash = \"$HASH\";|"
   ```

   Use `to_sri` for hexadecimal Homebrew-style sha256 values, `hash_file` for
   hashing a downloaded artifact, and `sed_inplace` for portable in-place
   edits. Keep each script scoped to metadata replacement only.

3. Register the package in `packages/default.nix`. For a package that builds
   on all configured systems, use the direct form:

   ```nix
   name = pkgs.callPackage ./name { };
   ```

   For a platform-specific package, guard it by host platform:

   ```nix
   name = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./name { } else null;
   ```

4. Make the updater executable and stage the new files before evaluating:

   ```bash
   chmod +x packages/<name>/update.sh
   git add packages/<name>
   ```

5. Verify locally on a system that matches the package's platform:

   ```bash
   nix build .#<name>
   bash packages/update.sh <name>
   git diff -- packages/<name>/default.nix
   ```

The scheduled workflow (`update-packages.yml`) then picks the new package up
automatically and includes it in the next update PR.

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
