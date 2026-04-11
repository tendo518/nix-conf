# Flake library functions
#
# Exports resolveModules: resolves module names from the registry.
# Supports exact match ("core/nix") or prefix expansion ("core" loads all submodules).
{
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  # Resolve module names (exact match or prefix match)
  resolveModules =
    registry: name:
    if registry ? ${name} then
      [ registry.${name} ]
    else
      let
        keys = builtins.filter (k: lib.hasPrefix "${name}/" k) (builtins.attrNames registry);
      in
      builtins.map (k: registry.${k}) keys;
in
{
  options.flake.lib = mkOption {
    type = types.lazyAttrsOf types.unspecified;
    default = { };
    description = "Library functions exported by the flake";
  };

  config.flake.lib = {
    inherit resolveModules;
  };
}