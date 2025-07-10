{
  flake.modules.nixos."hardware/disable-sleep" =
    {
      lib,
      ...
    }:
    {
      # disable sleep on some system
      systemd.targets.sleep.enable = false;
      systemd.targets.suspend.enable = false;
      systemd.targets.hibernate.enable = false;
      systemd.targets.hybrid-sleep.enable = false;
    };
}
