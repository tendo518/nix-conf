# Hardware configuration: kernel, modules, CPU
{ inputs, ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/hardware" =
    { lib, pkgs, config, ... }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
      ];

      boot = {
        tmp.cleanOnBoot = true;
        kernelPackages = pkgs.linuxPackages;

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

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.enableAllFirmware = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}