{
  flake.modules.nixos."networking/syncthing" = {

  };

  # Darwin uses home-manager for syncthing since macOS doesn't have
  # a native systemd-like service for syncthing
  flake.modules.darwin."networking/syncthing" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.syncthing ];
    };

  flake.modules.homeManager."networking/syncthing" = {

  };
}
