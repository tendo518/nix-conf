{
  flake.modules.nixos."desktop/bluetooth" = {
    # Bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
