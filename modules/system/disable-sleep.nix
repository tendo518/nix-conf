{
  flake.modules.nixos."system/disable-sleep" = _: {
    # Disable all sleep and hibernation targets on selected workstations.
    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
}
