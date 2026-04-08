# NFS mounts for NAS
{ ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/nfs" =
    { ... }:
    {
      boot.supportedFilesystems = [ "nfs" ];
      services.rpcbind.enable = true;

      systemd.mounts = [
        {
          type = "nfs";
          mountConfig.Options = "noatime,nfsvers=4.1";
          what = "nas-home-coin.local:/Public";
          where = "/mnt/NAS/Public/";
        }
        {
          type = "nfs";
          mountConfig.Options = "noatime,nfsvers=4.1";
          what = "nas-home-coin.local:/Photography";
          where = "/mnt/NAS/Photography/";
        }
      ];

      systemd.automounts = [
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/NAS/Public/";
        }
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/NAS/Photography/";
        }
      ];
    };
}
