# Main flake-parts configuration module
# Defines options and config for the flake
{
  inputs,
  lib,
  config,
  ...
}:
let
  # Import library functions from top-level lib directory
  flakeLib = import ../lib { inherit inputs; };
in
{
  # Module registry options
  options.flake.modules = {
    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
      description = "NixOS modules";
    };
    darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
      description = "Darwin modules";
    };
    homeManager = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
      description = "Home Manager modules (shared across all platforms)";
    };
    darwinHomeManager = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
      description = "Home Manager modules (Darwin only)";
    };
    nixosHomeManager = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
      description = "Home Manager modules (NixOS only)";
    };
  };

  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Library functions exported by the flake";
  };

  config = {
    # Auto-discover configurations from module registry
    flake.nixosConfigurations = flakeLib.mkSystemConfigs config "nixos";
    flake.darwinConfigurations = flakeLib.mkSystemConfigs config "darwin";

    # Export mkHost helper
    flake.lib = lib.mkDefault {
      mkHost = flakeLib.mkHost;
    };
  };
}
