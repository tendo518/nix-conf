# Platform lookup table for building host configurations
{ inputs }:
{
  darwin = {
    configPrefix = "darwinConfigurations/";
    systemBuilder = inputs.nix-darwin.lib.darwinSystem;
    agenixModule = inputs.agenix.darwinModules.default;
    hmModule = inputs.home-manager.darwinModules.home-manager;
    homeBase = "/Users";
  };
  nixos = {
    configPrefix = "nixosConfigurations/";
    systemBuilder = inputs.nixpkgs.lib.nixosSystem;
    agenixModule = inputs.agenix.nixosModules.default;
    hmModule = inputs.home-manager.nixosModules.home-manager;
    homeBase = "/home";
  };
}
