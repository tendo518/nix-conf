{
  flake.modules.nixos."hardware/fwupd" = {
    services.fwupd.enable = true;
  };
}
