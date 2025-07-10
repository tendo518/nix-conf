# Homepage: the LAN/tailnet entry page for the self-hosted services.
#   :80 - a host-agnostic dashboard linking each service to its own port.
_: {
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/homepage" = _: {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 8082;
      openFirewall = false;
      allowedHosts = "*";

      settings = {
        title = "server-lab-sardine";
        theme = "dark";
      };

      services = [
        {
          Services = [
            {
              Gitea = {
                href = "http://192.168.11.1:3000";
                description = "Self-hosted Git service";
                icon = "gitea.png";
                siteMonitor = "http://192.168.11.1:3000";
              };
            }
            {
              "Garage S3" = {
                href = "http://192.168.11.1:3900";
                description = "S3-compatible object storage API";
                icon = "🪣";
              };
            }
            {
              "Garage Web" = {
                href = "http://192.168.11.1:3902";
                description = "Static websites from Garage buckets";
                icon = "🌐";
              };
            }
            {
              "Garage Admin" = {
                href = "http://192.168.11.1:3903";
                description = "Garage cluster administration API";
                icon = "🛠️";
              };
            }
            {
              Cockpit = {
                href = "https://192.168.11.1:9090";
                description = "System and virtual machine console";
                icon = "🖥️";
                siteMonitor = "https://192.168.11.1:9090";
              };
            }
            {
              Netdata = {
                href = "http://192.168.11.1:19999";
                description = "Real-time metrics dashboard";
                icon = "netdata.png";
                siteMonitor = "http://192.168.11.1:19999";
              };
            }
          ];
        }
      ];

      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
            uptime = true;
          };
        }
      ];
    };

    networking.firewall.interfaces.lan0.allowedTCPPorts = [ 80 ];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 ];
  };
}
