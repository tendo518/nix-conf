# Hardware configuration for Intel Core i7-14700K + RTX 4070 Ti SUPER
{ inputs, ... }:
{
  flake.modules.nixos."hosts/desktop-lab-peace/hardware" =
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
            # NVMe and storage
            "nvme"
            "vmd"
            "xhci_pci"
            "ahci"
            "usbhid"
            "usb_storage"
            "sd_mod"
            # Encryption
            "dm-snapshot"
            "cryptd"
          ];
          kernelModules = [
            # MediaTek MT7922 WiFi driver
            "mt7921e"
          ];
        };

        # Intel KVM support
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.enableAllFirmware = true;

      # Intel CPU microcode updates
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      # Intel SoundWire audio (Raptor Lake uses mtl/tgl SOF drivers)
      hardware.firmware = with pkgs; [
        sof-firmware
      ];
    };
}