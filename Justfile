# List all available just commands in this Justfile.

# Usage: just
default:
    @just --list

# Set the default flake to use. (for nh version >= 1.10.0)
export NH_FLAKE := "."
nix := "nix --extra-experimental-features 'nix-command flakes'"

############################################################################
#
#  System Management
#
############################################################################

# Build for NixOS
[group('System Management')]
build-nixos hostname=`hostname -s` *args:
    nh os build -H {{ hostname }} . {{ args }}

# Build for Darwin
[group('System Management')]
build-darwin hostname=`hostname -s` *args:
    nh darwin build -H {{ hostname }} . {{ args }}

# Switch for NixOS
[group('System Management')]
switch-nixos hostname=`hostname -s` *args:
    nh os switch -H {{ hostname }} . {{ args }}

# Switch for Darwin
[group('System Management')]
switch-darwin hostname=`hostname -s` *args:
    nh darwin switch -H {{ hostname }} . {{ args }}

# Make the next NixOS generation the boot default (activate on reboot).
[group('System Management')]
boot-nixos hostname=`hostname -s` *args:
    nh os boot -H {{ hostname }} . {{ args }}

# Install NixOS on a new machine.
[group('System Management')]
install-nixos hostname ip_address:
    nixos-anywhere --flake .#{{ hostname }} root@{{ ip_address }}

# Install NixOS on a new machine over SSH (default target <hostname>.tailnet).
# Wipes the target disks; root SSH must work on the target.
[group('System Management')]
remote-install-nixos hostname target=(hostname + ".tailnet"):
    nixos-anywhere --flake .#{{ hostname }} root@{{ target }}

# Switch a remote NixOS host over SSH (default target <hostname>.tailnet).
[group('System Management')]
remote-switch-nixos hostname target=(hostname + ".tailnet") *args:
    nh os switch -H {{ hostname }} --target-host {{ target }} . {{ args }}

# Make the next generation the boot default on a remote NixOS host
# (default target <hostname>.tailnet).
[group('System Management')]
remote-boot-nixos hostname target=(hostname + ".tailnet") *args:
    nh os boot -H {{ hostname }} --target-host {{ target }} . {{ args }}

############################################################################
#
#  Raw Nix Commands
#
############################################################################

# Build for NixOS (raw)
[group('Raw Nix Commands')]
nix-build-nixos hostname=`hostname -s` *args:
    {{ nix }} build .#nixosConfigurations.{{ hostname }}.config.system.build.toplevel {{ args }}

# Build for Darwin (raw)
[group('Raw Nix Commands')]
nix-build-darwin hostname=`hostname -s` *args:
    {{ nix }} build .#darwinConfigurations.{{ hostname }}.system {{ args }}

# Switch for NixOS (raw)
[group('Raw Nix Commands')]
nix-switch-nixos hostname=`hostname -s` *args:
    sudo nixos-rebuild switch --flake .#{{ hostname }} {{ args }}

# Make the next NixOS generation the boot default (raw)
[group('Raw Nix Commands')]
nix-boot-nixos hostname=`hostname -s` *args:
    sudo nixos-rebuild boot --flake .#{{ hostname }} {{ args }}

# Switch for Darwin (raw)
[group('Raw Nix Commands')]
nix-switch-darwin hostname=`hostname -s` *args:
    sudo darwin-rebuild switch --flake .#{{ hostname }} {{ args }}

############################################################################
#
#  Maintenance
#
############################################################################

# Garbage collect unused nix store entries (system & user).
[group('Maintenance')]
clean:
    nh clean all --keep 3 --ask

# Update all flake inputs and switch system.
[group('Maintenance')]
up:
    {{ nix }} flake update

# Update a specific flake input.
[group('Maintenance')]
up-input input:
    {{ nix }} flake update {{ input }}

# List all NixOS system generations.
[group('Maintenance')]
generations:
    sudo nixos-rebuild list-generations | column -t

# List all NixOS system generations with detailed info.
[group('Maintenance')]
generations-full:
    sudo nixos-rebuild list-generations

# View nix-switch history.
[group('Maintenance')]
history:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild --list-generations; \
    else \
        nh os info; \
    fi

############################################################################
#
#  Utility
#
############################################################################

# Check the flake outputs.
[group('Utility')]
check:
    {{ nix }} flake check

# Check the flake outputs for all systems.
[group('Utility')]
check-all:
    {{ nix }} flake check --all-systems

# Format all Nix files in this repository.
[group('Utility')]
fmt:
    {{nix}} fmt

alias format := fmt

# List all the current garbage collection roots.
[group('nix')]
gcroot:
    ls -al /nix/var/nix/gcroots/auto/

# Edit an agenix secret file.
[group('Utility')]
edit-secret secret_path:
    cd "{{ justfile_directory() }}/secrets" && {{ nix }} run github:ryantm/agenix -- -e "$(basename {{ secret_path }})"

# Safely create an agenix secret for a password (hashes with sha-512).
[group('Utility')]
edit-password secret_path:
    cd "{{ justfile_directory() }}/secrets" && \
    FILENAME="$(basename {{ secret_path }})" && \
    echo "Enter password:" && \
    read -s PW && \
    HASH=$(echo "$PW" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 -s") && \
    echo -n "$HASH" > "$FILENAME.tmp" && \
    EDITOR="cp $FILENAME.tmp" {{ nix }} run github:ryantm/agenix -- -e "$FILENAME" && \
    rm -f "$FILENAME.tmp"
