{
  flake.modules.nixos."network/syncthing" = {

  };

  # Darwin uses home-manager for syncthing since macOS doesn't have
  # a native systemd-like service for syncthing
  flake.modules.darwin."network/syncthing" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.syncthing ];
    };

  flake.modules.homeManager."network/syncthing" = {

  };
}
