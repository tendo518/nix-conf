{
  flake.modules.nixos."hardware/smartd" = {
    # enable smartd to monitor hard drives
    # notify on potential risk
    services.smartd = {
      enable = true;
      autodetect = true;
      # notifications.x11.enable = true;
    };
  };
}
