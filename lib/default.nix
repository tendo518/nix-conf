# Library functions for the flake
{ inputs }:
let
  lib = inputs.nixpkgs.lib;
  platforms = import ./platforms.nix { inherit inputs; };
  resolveModules = import ./resolveModules.nix { inherit lib; };
  mkHostLib = import ./mkHost.nix { inherit inputs lib platforms; inherit (resolveModules) resolveModules validateModules; };
in
{
  inherit (mkHostLib) mkHost mkSystemConfigs;
  inherit (resolveModules) resolveModules validateModules;
  inherit platforms;
}
