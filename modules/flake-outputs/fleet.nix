# Fleet host configuration options
{
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  # Fleet host configuration submodule type
  hostConfigType = types.submodule {
    options = {
      useHomeManager = mkOption {
        type = types.bool;
        default = true;
      };
      modules = mkOption {
        type = types.listOf types.str;
        description = "List of module names to include";
      };
      user = mkOption {
        type = types.attrs;
        description = "User configuration";
      };
      stateVersion = mkOption {
        type = lib.types.either lib.types.str lib.types.int;
        description = "System state version";
      };
    };
  };
in
{
  options.fleet = {
    nixos = mkOption {
      type = types.attrsOf hostConfigType;
      default = { };
      description = "NixOS host configurations";
    };

    darwin = mkOption {
      type = types.attrsOf hostConfigType;
      default = { };
      description = "Darwin host configurations";
    };
  };
}
