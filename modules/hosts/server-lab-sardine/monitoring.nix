# Monitoring and alerting for the router.
# Netdata provides the dashboard plus built-in health alarms; vnstat tracks
# interface traffic; smartd watches the disk.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/monitoring" =
    { pkgs, ... }:
    {
      services.netdata = {
        enable = true;
        # The plain netdata package ships no dashboard UI in nixpkgs (the v2
        # UI is a separate component); netdataCloud bundles it.
        package = pkgs.netdataCloud;
        enableAnalyticsReporting = false;
      };
      services.vnstat.enable = true;
      services.smartd = {
        enable = true;
        autodetect = true;
      };

      # Netdata dashboard is only reachable from the LAN side.
      networking.firewall.interfaces.lan0.allowedTCPPorts = [
        19999
      ];
    };
}
