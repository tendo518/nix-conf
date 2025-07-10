{
  flake.modules.nixos."system/base" =
    { lib, ... }:
    {
      time.timeZone = lib.mkDefault "Asia/Shanghai";

      documentation = {
        enable = true;
        doc.enable = false;
        info.enable = false;

        # Enable man-db
        man.man-db.enable = true;
      };
      # Increase open files for all users
      systemd.user.settings.Manager = {
        DefaultLimitNOFILE = "524288:524288";
      };

      services.journald.extraConfig = ''
        SystemMaxUse=100M
        MaxFileSec=3day
      '';

      # speedup dns
      services.nscd.enableNsncd = true;
    };
}
