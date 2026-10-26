{
  flake.modules.nixos."apps/sunshine" =
    { hostContext, lib, ... }:
    {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = true;
      };

      # nixpkgs' Sunshine module still sets these obsolete Avahi options.
      services.avahi.publish = {
        enable = lib.mkForce null;
        userServices = lib.mkForce null;
      };

      # fix upstream: https://github.com/NixOS/nixpkgs/issues/455737
      hardware.uinput.enable = true;

      users.users.${hostContext.user.name}.extraGroups = [ "uinput" ];
    };
}
