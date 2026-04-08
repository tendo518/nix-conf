# Secure boot with lanzaboote
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/lanzaboote" =
    { pkgs, ... }: # inputs is captured from outer scope via lexical scoping
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      boot.loader.systemd-boot.enable = lib.mkForce false;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
    };
}
