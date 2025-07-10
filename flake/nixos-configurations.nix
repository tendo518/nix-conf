# Build nixosConfigurations from hosts.nixos
{
  config,
  inputs,
  ...
}:
let
  hostBuilder = import ./_lib/host-builder.nix { lib = inputs.nixpkgs.lib; };
in
{
  flake.nixosConfigurations =
    hostBuilder.mkHostConfigurations
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
