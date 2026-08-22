{
  flake.modules.nixos."apps/sunshine" =
    { pkgs, hostContext, ... }:
    {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = true;
      };

      # fix upstream: https://github.com/NixOS/nixpkgs/issues/455737
      hardware.uinput.enable = true;

      users.users.${hostContext.user.name}.extraGroups = [ "uinput" ];
    };
}
