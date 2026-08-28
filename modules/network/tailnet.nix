# Tailnet names, now resolved by MagicDNS (network/tailscale adds --accept-dns),
# so there is no manual /etc/hosts stuffing here. This module only generates
# ssh aliases. (Per-service subdomains of server-lab-sardine are resolved by
# the server's dnsmasq via a Tailscale restricted nameserver, set in the
# admin console — not in this repo.)
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
  flake.modules.home."network/tailnet" =
    { lib, ... }:
    {
      # ssh aliases: `ssh <name>.tailscale` just works (name resolved by
      # MagicDNS; here we only pin User / IdentityFile / control options).
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