{ config, ... }:
let
  overlays = builtins.attrValues (config.flake.overlays or { });
  nixpkgsConfig = {
    nixpkgs.config.allowUnfree = true;
    # nixpkgs.config.allowBroken = true;  # Allow building broken/incomplete packages
    nixpkgs.overlays = overlays;
  };
in
{
  flake.modules.nixos."core/nixpkgs" = nixpkgsConfig;
  flake.modules.darwin."core/nixpkgs" = nixpkgsConfig;
}
