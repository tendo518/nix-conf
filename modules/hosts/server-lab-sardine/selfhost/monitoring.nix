# Monitoring and alerting for the router.
# Netdata provides the dashboard plus built-in health alarms; vnstat tracks
# interface traffic; smartd watches the disk.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/monitoring" =
    { pkgs, ... }:
    {
      services.netdata = {
        enable = true;
        # The plain netdata package ships no dashboard UI in nixpkgs (the v2
        # UI is a separate component); netdataCloud bundles it.
        package = pkgs.netdataCloud;
        enableAnalyticsReporting = false;
        # Loopback only; the dashboard is served through the Caddy `/` route.
        config.web."bind to" = "127.0.0.1:19999";
      };
      services.vnstat.enable = true;
      services.smartd = {
        enable = true;
        autodetect = true;
      };
    };
}
