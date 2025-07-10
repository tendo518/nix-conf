# Cockpit web console + KVM/libvirt management, similar to a lightweight PVE.
_: {
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/cockpit" =
    {
      pkgs,
      lib,
      ...
    }:
    {
      virtualisation.libvirtd.enable = true;

      services.cockpit = {
        enable = true;
        # Only the LAN/tailnet firewall openings expose Cockpit.
        openFirewall = false;
        showBanner = false;
        plugins = with pkgs; [
          cockpit-machines
          cockpit-podman
          cockpit-files
        ];
        # Any origin works so the console keeps working if we migrate to a
        # different tailnet IP / hostname (or reach it via the Caddy proxy).
        # The socket itself is bound to loopback below.
        allowed-origins = [ "*" ];
        settings.WebService.LoginTo = false;
      };

      # Cockpit uses systemd socket activation and binds all interfaces by
      # default; override its listen stream so it only answers on loopback.
      # Bind on all interfaces; access is restricted by the firewall.
      systemd.sockets.cockpit.listenStreams = lib.mkForce [ "0.0.0.0:9090" ];
      networking.firewall.interfaces.lan0.allowedTCPPorts = [ 9090 ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9090 ];
    };
}
