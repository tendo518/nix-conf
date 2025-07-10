{
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime,nfsvers=4.1";
      };
      what = "nas-home-coin.local:/Public";
      where = "/mnt/NAS/Public/";
    }
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime,nfsvers=4.1";
      };
      what = "nas-home-coin.local:/Photography";
      where = "/mnt/NAS/Photography/";
    }

    # {
    #   type = "xfs";
    #   what = "/dev/"
    # }

  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/NAS/Public/";
    }
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/NAS/Photography/";
    }
  ];
}
