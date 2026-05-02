# Hardware: kernel, CPU, filesystems
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-lab-peace/hardware" =
    { config, ... }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
      ];

      boot.initrd.availableKernelModules = [
        "vmd"
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/fc26d9f6-470c-4a4f-97d8-1b524165b632";
        fsType = "btrfs";
        options = [
          "subvol=@root"
          "compress=zstd"
        ];
      };

      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/fc26d9f6-470c-4a4f-97d8-1b524165b632";
        fsType = "btrfs";
        options = [
          "subvol=@home"
          "compress=zstd"
        ];
      };

      fileSystems."/nix" = {
        device = "/dev/disk/by-uuid/fc26d9f6-470c-4a4f-97d8-1b524165b632";
        fsType = "btrfs";
        options = [
          "subvol=@nix"
          "compress=zstd"
          "noatime"
        ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/00A4-07C4";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
