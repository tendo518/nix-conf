# Lenovo ThinkPad X13s (aarch64)
{ inputs, ... }:
{
  hosts.nixos.laptop-solar-chiyoko = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/laptop-solar-chiyoko"
      "network/tailscale"
      "hardware"
    ];
    excludeModules = [
      "apps/deskflow"
      "apps/gaming"
      "apps/wireshark"
      "desktop/plasma"
      "hardware/disable-sleep"
      "hardware/nvidia"
      "system/virtualisation"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      extraGroups = [ "video" ];
    };
    hostPlatform = "aarch64-linux";
    stateVersion = "26.05";
  };

  flake.modules.nixos."hosts/laptop-solar-chiyoko" =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
        inputs.disko.nixosModules.disko
      ];

      disko.devices = {
        disk.main = {
          device = "/dev/nvme0n1";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0022"
                    "dmask=0022"
                  ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" ];
                    };
                  };
                };
              };
            };
          };
        };
      };

      nix.settings = {
        cores = 4;
        max-jobs = 2;
      };
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        pd.enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          # PCIE_ASPM_ON_BAT = "powersupersave";
        };
      };

      environment.systemPackages = with pkgs; [
        libcamera
        libreoffice
        zathura
        telegram-desktop
        chromium
        bitwarden-desktop
        darktable
        antigravity
        moonlight-qt
        ghostty
        retedo-mono
      ];
      # Network
      programs.clash-verge = {
        enable = true;
        tunMode = true;
        serviceMode = true;
      };

      # IDK not this cause failed to boot
      # fprintd — Synaptics Prometheus sensor (standard libfprint, not TOD)
      # services.fprintd.enable = true;

      boot.loader.systemd-boot.edk2-uefi-shell.enable = true;

      networking.useDHCP = lib.mkDefault true;
      # https://wiki.gentoo.org/wiki/NetworkManager#Failed_to_add_new_connection:_802.1x_connections_must_have_IWD_provisioning_files
      networking.networkmanager.wifi.backend = "wpa_supplicant";

      services = {
        v2raya.enable = true;
        fwupd.enable = true;
      };
    };

  flake.modules.homeManager."hosts/laptop-solar-chiyoko" =
    { ... }:
    {
      imports = [ ];
    };
}
