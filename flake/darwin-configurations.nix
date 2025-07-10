# Build darwinConfigurations from hosts.darwin
{
  config,
  inputs,
  ...
}:
let
  hostBuilder = import ./_lib/host-builder.nix { lib = inputs.nixpkgs.lib; };
in
{
  flake.darwinConfigurations =
    hostBuilder.mkHostConfigurations
      {
        inherit inputs;
        moduleRegistries = config.flake.modules;
      }
      {
        builder = inputs.nix-darwin.lib.darwinSystem;
        agenixModule = inputs.agenix.darwinModules.default;
        hmModule = inputs.home-manager.darwinModules.home-manager;
        homeBase = "/Users";
        backupFileExtension = "home-manager.backup";
      }
      config.hosts.darwin
      "darwin";
}
