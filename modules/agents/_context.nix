# Shared connection selection, model references, defaults, and runtime secret paths.
{
  config,
  lib,
  settings,
}:
let
  registry = import ./_providers.nix;
  catalog = import ./_models;
  unknown = builtins.attrNames (builtins.removeAttrs settings (builtins.attrNames registry));
  invalidEnable = builtins.attrNames (
    lib.filterAttrs (_: value: !(value ? enable) || !builtins.isBool value.enable) settings
  );

  selected =
    if unknown != [ ] then
      throw "agents: unknown provider setting: ${toString unknown}"
    else if invalidEnable != [ ] then
      throw "agents: missing or non-boolean provider enable setting: ${toString invalidEnable}"
    else
      lib.mapAttrs (
        name: selection:
        let
          provider = registry.${name};
          agentConfig = builtins.removeAttrs selection [ "enable" ];
          models = lib.mapAttrs (
            key: declaration:
            (catalog.${declaration.model}
              or (throw "agents: unknown model declaration: ${name}/${key} -> ${declaration.model}")
            )
            // {
              inherit (declaration) id;
            }
          ) provider.models;
          defaultModelKey = agentConfig.defaultModel or provider.defaultModel;
        in
        provider
        // {
          inherit agentConfig defaultModelKey models;
          defaultModel =
            models.${defaultModelKey} or (throw "agents: unknown default model: ${name}/${defaultModelKey}");
          secretPath = config.age.secrets.${provider.secret}.path;
        }
      ) (lib.filterAttrs (_: selection: selection.enable) settings);

  # Wrapper-based clients do not need a global default.
  defaultProvider =
    lib.findSingle (name: selected.${name}.agentConfig.default or false)
      (throw "agents: select one default provider in the agent settings")
      (throw "agents: multiple providers are marked as default in the agent settings")
      (builtins.attrNames selected);
in
{
  inherit selected defaultProvider;
  defaultModel = selected.${defaultProvider}.defaultModel;
  ageSecrets = lib.listToAttrs (
    map (
      provider:
      lib.nameValuePair provider.secret {
        file = ../../secrets + "/${provider.secret}.age";
      }
    ) (lib.attrValues selected)
  );
}
