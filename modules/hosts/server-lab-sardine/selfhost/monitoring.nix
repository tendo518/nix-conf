# Monitoring and alerting for the router.
# Netdata provides the dashboard plus built-in health alarms; vnstat tracks
# interface traffic; smartd watches the disk.
_: {
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/monitoring" =
    { pkgs, ... }:
    {
      services.netdata = {
        enable = true;
        # The plain netdata package ships no dashboard UI in nixpkgs (the v2
        # UI is a separate component); netdataCloud bundles it.
        package = pkgs.netdataCloud;
        enableAnalyticsReporting = false;
        # Bind on all interfaces; access is restricted by the firewall.
        config.web."bind to" = "0.0.0.0:19999";
      };
      services.vnstat.enable = true;
      services.smartd = {
        enable = true;
        autodetect = true;
      };
      networking.firewall.interfaces.lan0.allowedTCPPorts = [ 19999 ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 19999 ];
    };
}
