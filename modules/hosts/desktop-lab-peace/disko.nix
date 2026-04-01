# Disk configuration with disko
# LUKS + btrfs layout for desktop workstation
# Main disk: Predator SSD GM7 1TB (nvme0n1)
# Data disk: WD_BLACK SN770 2TB (nvme1n1)
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-lab-peace/disko" =
    { pkgs, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices = {
        disk = {
          main = {
            # Predator SSD GM7 1TB
            device = lib.mkDefault "/dev/nvme0n1";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  name = "NIXBOOT";
                  size = "1G";
                  type = "EF00"; # EFI system partition
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
                luks = {
                  name = "NIXLUKS";
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "cryptroot";
                    # Enable TPM2 support after installation
                    settings = {
                      allowDiscards = true;
                      crypttabExtraOpts = [ "fido2-device=auto" ];
                    };
                    # Additional TPM2 enrollment options
                    extraFormatArgs = [
                      "--tpm2-device=auto"
                      "--tpm2-pcrs=0+7"
                    ];
                    content = {
                      type = "btrfs";
                      extraArgs = [ "-f" ];
                      subvolumes = {
                        root = {
                          mountpoint = "/";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        home = {
                          mountpoint = "/home";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        nix = {
                          mountpoint = "/nix";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        persist = {
                          mountpoint = "/persist";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        log = {
                          mountpoint = "/var/log";
                          mountOptions = [
                            "compress=zstd"
                            "noatime"
                          ];
                        };
                        swap = {
                          mountpoint = "/.swapvol";
                          mountOptions = [
                            "noatime"
                          ];
                        };
                      };
                    };
                  };
                };
              };
            };
          };

          # Data disk: WD_BLACK SN770 2TB
          data = {
            device = lib.mkDefault "/dev/nvme1n1";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                data = {
                  name = "DATA";
                  size = "100%";
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      data = {
                        mountpoint = "/mnt/data";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };

      # Required for btrfs rollback/cleanup on boot
      boot.initrd.systemd.enable = true;
    };
}