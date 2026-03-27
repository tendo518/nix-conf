# Laptop for travel
# Fleet configuration and module registrations
{ inputs, ... }:
{
  # Fleet host definition
  fleet.nixos.laptop-solar-chiyoko = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/laptop-solar-chiyoko"
      "desktop/plasma"
      "hardware/smartd"
      "hardware/disable-sleep"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.11";
      extraGroups = [ "networkmanager" ];
      passwordSecret = "tendo-password.age";
    };
    stateVersion = "25.11";
  };

  # NixOS system configuration
  flake.modules.nixos."hosts/laptop-solar-chiyoko" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
      ];

      nix.settings = {
        cores = 4;
        max-jobs = 2;
      };

      environment.systemPackages = with pkgs; [
        wechat
        qq
        libreoffice
        zathura
        telegram-desktop
        chromium
        bitwarden-desktop
        darktable
        antigravity
        deskflow
        ghostty
        iosevka-lnxw
      ];

      boot = {
        kernelPackages = pkgs.linuxPackages_zen;

        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "thunderbolt"
            "usb_storage"
            "sd_mod"
          ];
          kernelModules = [ ];
        };

        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];

        loader.systemd-boot = {
          edk2-uefi-shell.enable = true;
          windows = {
            "win11" = {
              title = "Windows 11";
              efiDeviceHandle = "HD0d";
              sortKey = "z_windows";
            };
          };
        };
      };

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/72662836-19da-4d7a-9da4-6699d77e3862";
        fsType = "xfs";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/E6AE-21BC";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [ ];

      networking.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      services = {
        v2raya.enable = true;
        userborn.enable = true;
        fwupd.enable = true;
      };

      system.etc.overlay = {
        enable = true;
        mutable = false;
      };
    };

  flake.modules.homeManager."hosts/laptop-solar-chiyoko" = { ... }: {
    imports = [ ];
  };
}