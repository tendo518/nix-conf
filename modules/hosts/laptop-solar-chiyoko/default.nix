# Lenovo ThinkPad X13s (aarch64)
{ inputs, ... }:
{
  hosts.nixos.laptop-solar-chiyoko = {
    modules = [
      "core"
      "system"
      "development"
      "apps/chrome"
      "apps/dropbox"
      "apps/fcitx5"
      "apps/firefox"
      "apps/ghostty"
      "apps/kitty"
      "apps/mpv"
      "apps/vscode"
      "network"
      "desktop"
      "hosts/laptop-solar-chiyoko"
      "network/tailscale"
      "hardware/lenovo-x13s"
      "hardware/fwupd"
      "hardware/smartd"
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
      extraGroups = [ ];
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
                  mountOptions = [ "fmask=0022" "dmask=0022" ];
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
                      mountOptions = [ "compress=zstd" "noatime" ];
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

      environment.systemPackages = with pkgs; [
        libreoffice
        zathura
        telegram-desktop
        chromium
        bitwarden-desktop
        darktable
        antigravity
        ghostty
        retedo-mono
      ];

      boot.loader.systemd-boot.edk2-uefi-shell.enable = true;

      networking.useDHCP = lib.mkDefault true;

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
