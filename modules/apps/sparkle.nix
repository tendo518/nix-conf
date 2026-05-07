# Sparkle proxy application
{
  flake.modules.nixos."apps/sparkle" =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.sparkle ];

      # TUN mode capabilities
      security.wrappers.sparkle = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_bind_service,cap_net_raw,cap_net_admin+ep";
        source = "${lib.getExe pkgs.sparkle}";
      };

      # Service mode
      systemd.services.sparkle = {
        enable = true;
        description = "Sparkle Service Mode";
        serviceConfig = {
          ExecStart = "${pkgs.sparkle}/lib/sparkle/resources/files/sparkle-service";
          Restart = "on-failure";
          ProtectSystem = "strict";
          NoNewPrivileges = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          SystemCallArchitectures = "native";
          PrivateTmp = true;
          PrivateMounts = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          LockPersonality = true;
          RestrictRealtime = true;
          RuntimeDirectory = "sparkle";
          ProtectClock = true;
          MemoryDenyWriteExecute = true;
          RestrictSUIDSGID = true;
          RestrictNamespaces = [ "~user cgroup mnt uts" ];
          RestrictAddressFamilies = [ "AF_INET AF_INET6 AF_NETLINK AF_PACKET AF_UNIX" ];
          CapabilityBoundingSet = [ "CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_SETUID CAP_SETGID CAP_CHOWN CAP_MKNOD" ];
          SystemCallFilter = [ "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @sandbox @setuid @swap @timer" ];
          SystemCallErrorNumber = "EPERM";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
