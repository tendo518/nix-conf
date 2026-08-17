# Cockpit web console + KVM/libvirt management, similar to a lightweight PVE.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/cockpit" =
    { pkgs, ... }:
    {
      virtualisation.libvirtd.enable = true;

      services.cockpit = {
        enable = true;
        # Don't expose port 9090 to the WAN; allow only LAN and tailnet.
        openFirewall = false;
        showBanner = false;
        plugins = with pkgs; [
          cockpit-machines
          cockpit-podman
          cockpit-files
        ];
        allowed-origins = [
          "https://localhost:9090"
          "https://100.70.253.124:9090"
          "https://192.168.11.1:9090"
          # Browser origin when reached through the Caddy proxy.
          "http://cockpit.lan"
          "http://server-lab-sardine.tailscale"
          "http://100.70.253.124"
        ];
        settings.WebService.LoginTo = false;
      };

      networking.firewall.interfaces = {
        lan0.allowedTCPPorts = [ 9090 ];
        tailscale0.allowedTCPPorts = [ 9090 ];
      };
    };
}
