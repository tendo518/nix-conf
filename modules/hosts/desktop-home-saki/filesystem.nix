# Filesystems and swap
{ ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/filesystem" = { ... }: {
    boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-label/NIXLUKS";
    boot.initrd.systemd.enable = true;

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
  };
}