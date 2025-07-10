{
  flake.modules.nixos."apps/deskflow" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.deskflow ];

      networking.firewall.allowedTCPPorts = [ 24800 ];
    };
}
