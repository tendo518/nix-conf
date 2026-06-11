{
  flake.modules.nixos."system/base" =
    { lib, pkgs, ... }:
    {
      time.timeZone = lib.mkDefault "Asia/Shanghai";

      # enable nix-ld to support some non-patched packages
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # Common FHS libraries needed by precompiled Python wheels and other non-Nix binaries
          zlib
          glib
          libGL
          libxcb
          stdenv.cc.cc
        ];
      };
      documentation = {
        enable = true;
        doc.enable = false;
        info.enable = false;

        # Enable man-db
        man.man-db.enable = true;
      };
      # Increase open files for all users
      systemd.user.extraConfig = ''
        DefaultLimitNOFILE=524288:524288
      '';

      services.journald.extraConfig = ''
        SystemMaxUse=100M
        MaxFileSec=3day
      '';

      # speedup dns
      services.nscd.enableNsncd = true;
    };
}
