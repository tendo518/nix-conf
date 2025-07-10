{
  flake.modules.nixos."system/oomd" =
    { lib, ... }:
    {
      systemd.oomd = {
        enable = lib.mkDefault true;
        enableRootSlice = lib.mkDefault true;
        enableSystemSlice = lib.mkDefault true;
        enableUserSlices = lib.mkDefault true;
      };
    };
}
