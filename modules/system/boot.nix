{
  flake.modules.nixos."system/boot" =
    { pkgs, lib, ... }:
    {
      # Bootloader
      boot.loader.systemd-boot = {
        enable = lib.mkDefault true; # some may override this, e.g. lanzaboote
        # we use Git for version control, so we don't need to keep too many generations.
        configurationLimit = lib.mkDefault 10;
        # pick the highest resolution for systemd-boot's console.
        consoleMode = lib.mkDefault "max";
      };
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.timeout = lib.mkDefault 5; # wait for x seconds to select the boot entry
      boot.initrd.systemd.enable = true;
      boot.initrd.compressor = "zstd";

      # LTS Kernel
      # boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    };
}
