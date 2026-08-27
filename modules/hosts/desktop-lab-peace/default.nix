# Desktop workstation at lab
# Host configuration and module registrations
{ ... }:
{
  # Host definition
  hosts.nixos.desktop-lab-peace = {
    modules = [
      "core"
      "system"
      "development"
      "agents"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-lab-peace"
      "hardware"
    ];
    excludeModules = [
      "apps/gaming"
      "desktop/niri"
      "hardware/lenovo-x13s"
    ];
    user = {
      name = "pengwy";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      # extraGroups = [ ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "26.05";
  };

  # Subnet routing is consolidated on server-lab-sardine (which sits directly
  # on 10.16.0.0/17 and reaches 172.18.x via its gateway). This host no longer
  # advertises routes and reverts to the tailnet default ("client"): it accepts
  # the routes the server advertises (`--accept-routes`, set in
  # modules/network/tailscale.nix) so it can reach remote subnets too.
  flake.modules.nixos."hosts/desktop-lab-peace" =
    { pkgs, ... }:
    {
      # Now that server-lab-sardine advertises the lab subnets, this host would
      # route traffic to all of them through Tailscale (its policy rules live at
      # priority 5200-5500). Install higher-priority rules (2500) that jump back
      # to the main table so direct LAN paths win -- exactly what Tailscale
      # documents for LAN traffic overlapping advertised subnet routes:
      #   - 10.16.0.0/17     this host's own directly-connected LAN (eno1)
      #   - 172.18.36.0/23   lab subnet (NAS 172.18.36.x) via default gateway
      #   - 172.18.34.0/23   lab subnet via default gateway
      systemd.services.prevent-lan-tailscale-overlap = {
        description = "Route 10.16.0.0/17 + lab 172.18/23 via main table, not Tailscale";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "tailscaled.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.iproute2 ];
        script = ''
          ip rule add to 10.16.0.0/17 priority 2500 lookup main || true
          ip rule add to 172.18.36.0/23 priority 2500 lookup main || true
          ip rule add to 172.18.34.0/23 priority 2500 lookup main || true
        '';
      };
    };
}
