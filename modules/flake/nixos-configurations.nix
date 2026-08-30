# Build nixosConfigurations from hosts.nixos
{
  config,
  framework,
  inputs,
  ...
}:
{
  flake.nixosConfigurations =
    framework.mkHostConfigurations
      {
        inherit inputs;
        moduleRegistries = config.flake.modules;
      }
      {
        builder = inputs.nixpkgs.lib.nixosSystem;
        agenixModule = inputs.agenix.nixosModules.default;
        hmModule = inputs.home-manager.nixosModules.home-manager;
        homeBase = "/home";
        backupFileExtension = "hm-backup";
      }
      config.hosts.nixos
      "nixos";
}
