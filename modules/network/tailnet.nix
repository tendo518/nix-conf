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
    { lib, ... }:
    {
      # System-level /etc/hosts on macOS too, so the whole OS (browser, curl,
      # ...) resolves <host>.tailscale. Same source table as NixOS; no
      # per-application host config. Keeps the stock macOS entries.
      environment.etc."hosts".text = ''
        ##
        # Host Database
        #
        # localhost is used to configure the loopback interface
        # when the system is booting.  Do not change this entry.
        ##
        127.0.0.1	localhost
        255.255.255.255	broadcasthost
        ::1             localhost

        # Tailscale hosts (single source: tailnet.nix)
        ${lib.concatStringsSep "\n" (map (h: "${h.ip} ${h.name}.tailscale") tailnetHosts)}
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
