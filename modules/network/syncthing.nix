{
  flake.modules.nixos."network/syncthing" =
    { lib, ... }:
    {
      services.syncthing = {
        enable = true;
        settings.options.globalAnnounceEnabled = false;
      };

      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [
        22000
        21027
      ];
    };

  # Darwin uses home-manager for syncthing since macOS doesn't have
  # a native systemd-like service for syncthing
  flake.modules.darwin."network/syncthing" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.syncthing ];
    };

  flake.modules.home."network/syncthing" = {

  };
}
