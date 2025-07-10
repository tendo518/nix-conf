{
  flake.modules.nixos."system/smartd" = {
    # enable smartd to monitor hard drives
    # notify on potential risk
    services.smartd = {
      enable = true;
      autodetect = true;
      # notifications.x11.enable = true;
    };
  };
}
