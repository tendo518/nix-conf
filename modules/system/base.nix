{
  flake.modules.nixos."system/base" =
    { lib, pkgs, ... }:
    {
      time.timeZone = lib.mkDefault "Asia/Shanghai";
      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

      # Basic packages
      environment.systemPackages =
        with pkgs;
        [
          git
          wget
          curl
          vim
          # system tools
          psmisc # killall/pstree/prtstat/fuser/...
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          efibootmgr
          nfs-utils
          lm_sensors # for `sensors` command
          ethtool
          pciutils # lspci
          usbutils # lsusb
          hdparm # for disk performance, command
          dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
          parted
        ];
      # enable nix-ld to support some non-patched packages
      programs.nix-ld.enable = true;
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
