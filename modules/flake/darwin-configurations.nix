# Build darwinConfigurations from hosts.darwin
{
  config,
  inputs,
  lib,
  ...
}:
{
  config.flake.darwinConfigurations = config.flake.lib.mkHostConfigurations inputs {
    builder = inputs.nix-darwin.lib.darwinSystem;
    agenixModule = inputs.agenix.darwinModules.default;
    hmModule = inputs.home-manager.darwinModules.home-manager;
    homeBase = "/Users";
    backupFileExtension = "home-manager.backup";
  } config.hosts.darwin "darwin";
}
