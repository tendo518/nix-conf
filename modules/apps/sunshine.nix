{
  flake.modules.nixos."apps/sunshine" =
    { pkgs, config, ... }:
    {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = true;
      };

      # fix upstream: https://github.com/NixOS/nixpkgs/issues/455737
      hardware.uinput.enable = true;

      users.users.${config.host.user.name}.extraGroups = [ "uinput" ];
    };
}
