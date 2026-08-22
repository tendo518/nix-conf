# Build nixosConfigurations from hosts.nixos
{
  config,
  inputs,
  lib,
  ...
}:
{
  config.flake.nixosConfigurations = config.hostBuilder inputs {
    builder = inputs.nixpkgs.lib.nixosSystem;
    agenixModule = inputs.agenix.nixosModules.default;
    hmModule = inputs.home-manager.nixosModules.home-manager;
    homeBase = "/home";
    backupFileExtension = "hm-backup";
  } config.hosts.nixos "nixos";
}
