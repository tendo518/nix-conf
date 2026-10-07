{ config, ... }:
let
  overlays = builtins.attrValues (config.flake.overlays or { });
  nixpkgsConfig = {
    nixpkgs.overlays = overlays;
  };
in
{
  flake.modules.nixos."core/nixpkgs" = nixpkgsConfig;
  flake.modules.darwin."core/nixpkgs" = nixpkgsConfig;
}
