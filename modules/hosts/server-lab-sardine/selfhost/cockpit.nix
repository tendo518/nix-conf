# Cockpit web console + KVM/libvirt management, similar to a lightweight PVE.
{ ... }:
{
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
        # Don't open 9090 in the firewall at all; loopback only via Caddy.
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
      # Caddy proxies /cockpit -> https://127.0.0.1:9090.
      systemd.sockets.cockpit.listenStreams = lib.mkForce [ "127.0.0.1:9090" ];
    };
}
