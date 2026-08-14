# Hardware and disk layout recovered from server-lab-sardine.
#
# The remote machine has a single 465.8G SATA SSD:
#   - sda1: 512M ESP  (partlabel disk-main-ESP)
#   - sda2: rest XFS  (partlabel disk-main-root)
# Keep the disko device references stable by using /dev/disk/by-id rather
# than the ephemeral /dev/sda path.
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/hardware" =
    { config, ... }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
        inputs.disko.nixosModules.disko
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      disko.devices = {
        disk.main = {
          device = "/dev/disk/by-id/ata-WDC_WDS500G2B0A-00SM50_190572800233";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0077"
                    "dmask=0077"
                  ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = "/";
                  mountOptions = [ "defaults" ];
                };
              };
            };
          };
        };
      };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
