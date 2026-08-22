{ config, framework, ... }:
let
  overlays = builtins.attrValues (config.flake.overlays or { });
  nixpkgsConfig = {
    nixpkgs.config.allowUnfree = true;
    # nixpkgs.config.allowBroken = true;  # Allow building broken/incomplete packages
    nixpkgs.overlays = overlays;
  };
in
framework.osModule "core/nixpkgs" nixpkgsConfig
