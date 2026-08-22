let
  basePackages =
    pkgs: with pkgs; [
      git
      wget
      curl
      vim
    ];
in
{
  flake.modules.nixos."core/packages" =
    { lib, pkgs, ... }:
    {
      environment.systemPackages =
        basePackages pkgs
        ++ [ pkgs.psmisc ] # killall/pstree/prtstat/fuser/...
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            efibootmgr
            nfs-utils
            lm_sensors # for `sensors` command
            ethtool
            pciutils # lspci
            usbutils # lsusb
            hdparm # for disk performance, command
            dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
            parted
          ]
        );
    };
  flake.modules.darwin."core/packages" =
    { pkgs, ... }:
    {
      environment.systemPackages = basePackages pkgs;
    };
}
