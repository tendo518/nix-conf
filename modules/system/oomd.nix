{
  flake.modules.nixos."system/oomd" =
    { lib, ... }:
    {
      # Enable systemd-oomd (Out-Of-Memory Daemon)
      # systemd-oomd monitors system memory and kills processes when memory pressure is too high
      systemd.oomd.enable = lib.mkDefault true;
    };
}
