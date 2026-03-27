# Fleet host configuration options
{
  lib,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.fleet = {
    nixos = mkOption {
      type = types.attrsOf (
        types.submodule {
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
              type = types.str;
              description = "System state version";
            };
          };
        }
      );
      default = { };
      description = "NixOS host configurations";
    };

    darwin = mkOption {
      type = types.attrsOf (
        types.submodule {
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
              type = types.str;
              description = "System state version";
            };
          };
        }
      );
      default = { };
      description = "Darwin host configurations";
    };
  };
}