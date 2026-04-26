# Hardware: kernel, CPU, filesystems, LUKS, secure boot
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/hardware" =
    { config, ... }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      # Kernel and hardware detection
      boot = {
        tmp.cleanOnBoot = true;

        initrd = {
          availableKernelModules = [
            "vmd"
            "xhci_pci"
            "ahci"
            "nvme"
            "usbhid"
            "usb_storage"
            "sd_mod"
          ];
          kernelModules = [
            "dm-snapshot"
            "cryptd"
          ];
        };

        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };

      # LUKS encryption
      boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-label/NIXLUKS";
      boot.initrd.systemd.enable = true;

      # Filesystems
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "btrfs";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [ ];

      # Secure boot with lanzaboote
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      # Platform and firmware
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.enableAllFirmware = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
