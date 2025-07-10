# Module resolution functions
{ lib }:
let
  # Resolve a module name to a list of module values
  # - Exact match: "apps/kitty" → [ registry.apps.kitty ]
  # - Prefix match: "apps" → [ registry.apps.kitty, registry.apps.firefox, ... ]
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
  inherit resolveModules;

  # Validate that all requested modules are registered
  validateModules =
    systemType: sysRegistry: hmRegistry: modules:
    let
      check =
        name:
        let
          sysHits = resolveModules sysRegistry name;
          hmHits = resolveModules hmRegistry name;
        in
        if sysHits != [ ] || hmHits != [ ] then
          true
        else
          throw "Module '${name}' is not registered in flake.modules.${systemType} or flake.modules.homeManager";
    in
    builtins.deepSeq (builtins.map check modules) modules;
}
