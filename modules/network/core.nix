{
  flake.modules.nixos."network/core" =
    { config, ... }:
    {
      networking.hostName = config.host.hostname;
      networking.usePredictableInterfaceNames = true;

      # Network discovery, mDNS
      # With this enabled, you can access your machine at <hostname>.local
      # it's more convenient than using the IP address.
      # https://avahi.org/
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          domain = true;
          userServices = true;
        };
      };

      # Use an NTP server located in the mainland of China to synchronize the system time
      networking.timeServers = [
        "ntp.aliyun.com" # Aliyun NTP Server
        "ntp.tencent.com" # Tencent NTP Server
      ];

      # Note that changes made in this way will be discarded when switching configurations.
      environment.etc.hosts.mode = "0644";

      # DNS configuration - this works fine with avahi
      services.resolved = {
        enable = true;
        settings = {
          Resolve = {
            MulticastDNS = true;
            LLMNR = "true";
          };
        };
      };
      ### https://wiki.archlinux.org/title/Sysctl#Improving_performance
      boot.kernelModules = [ "tcp_bbr" ];
      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "cake";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };
}
