# Single source of truth for tailnet machines (no MagicDNS):
#   name -> tailscale IP -> ssh user
#
# Consumed by:
#   - NixOS: networking.hosts, so every machine resolves <name>.tailscale
#   - Home:  programs.ssh.settings, so `ssh <name>.tailscale` just works
{ ... }:
let
  tailnetHosts = [
    {
      name = "desktop-home-saki";
      ip = "100.124.50.41";
      sshUser = "tendo";
    }
    {
      name = "desktop-lab-peace";
      ip = "100.66.176.74";
      sshUser = "pengwy";
    }
    {
      name = "laptop-solar-chiyoko";
      ip = "100.111.132.42";
      sshUser = "tendo";
    }
    {
      name = "laptop-solar-modoka";
      ip = "100.112.217.3";
      sshUser = "tendo";
    }
    {
      name = "server-lab-sardine";
      ip = "100.81.243.74";
      sshUser = "tendo";
    }
  ];
in
{
  flake.modules.nixos."network/tailnet" =
    { lib, ... }:
    {
      # <name>.tailscale -> tailscale IP for every machine on the tailnet.
      networking.hosts = lib.listToAttrs (
        map (h: {
          name = h.ip;
          value = [ "${h.name}.tailscale" ];
        }) tailnetHosts
      );
    };

  flake.modules.darwin."network/tailnet" =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # Keep /etc/hosts a real, writable file: append the tailnet host table
      # between `# BEGIN/END Nix-managed` markers via an activation script
      # (approach from nix-darwin#1831) instead of the `environment.etc`
      # symlink, which some tools choke on. Non-Nix lines are preserved;
      # macOS resolver / MagicDNS are untouched.
      #
      # Hook into nix-darwin's `extraActivation` (not a newly-created step,
      # which nix-darwin wouldn't pull into the activation chain).
      system.activationScripts.extraActivation.text =
        let
          awk = lib.getExe pkgs.gawk;
          tailnetLines = lib.concatStringsSep "\n" (
            map (h: "${h.ip} ${h.name}.tailscale") tailnetHosts
          );
        in
        ''
          printf >&2 'setting up /etc/hosts...\n'
          hostsOriginal=""
          if [[ -f /etc/hosts ]]; then
            hostsOriginal="$(${awk} '
              /^# BEGIN Nix-managed$/ {
                inManaged=1
                managed=$0 ORS
                next
              }
              inManaged {
                managed=managed $0 ORS
                if (/^# END Nix-managed$/) {
                  inManaged=0
                  managed=""
                }
                next
              }
              { print }
              END {
                if (inManaged) printf "%s", managed
              }
            ' /etc/hosts)"
          fi
          {
            if [[ -n "$hostsOriginal" ]]; then
              printf '%s\n' "$hostsOriginal"
            fi
            printf '# BEGIN Nix-managed\n'
            printf '%s\n' '${tailnetLines}'
            printf '# END Nix-managed\n'
          } > /etc/hosts
        '';
    };

  flake.modules.home."network/tailnet" =
    { lib, ... }:
    {
      # ssh aliases generated from the same list.
      programs.ssh.settings = lib.listToAttrs (
        map (h: {
          name = "${h.name}.tailscale";
          value = {
            Hostname = h.ip;
            User = h.sshUser;
            IdentityFile = "~/.ssh/id_ed25519";
          };
        }) tailnetHosts
      );
    };
}
