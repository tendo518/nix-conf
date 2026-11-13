{ config, lib, agent }:
let
  providers = import ./_providers;
  agentSettings = (import ./_agents.nix).${agent};
  providerNames = builtins.attrNames providers;
  unknownSettings = builtins.attrNames (builtins.removeAttrs agentSettings providerNames);
  missingSettings = builtins.attrNames (builtins.removeAttrs providers (builtins.attrNames agentSettings));
  invalidEnable = builtins.filter (
    name: !(agentSettings.${name} ? enable) || !builtins.isBool agentSettings.${name}.enable
  ) (builtins.attrNames agentSettings);
in
{
  # Agent settings include provider enablement and per-provider adapter options.
  selectProviders =
    if unknownSettings != [ ] then
      throw "agents: unknown provider setting: ${toString unknownSettings}"
    else if missingSettings != [ ] then
      throw "agents: missing provider setting: ${toString missingSettings}"
    else if invalidEnable != [ ] then
      throw "agents: missing or non-boolean provider enable setting: ${toString invalidEnable}"
    else
      lib.mapAttrs (
        name: provider:
        provider
        // {
          agentConfig = builtins.removeAttrs agentSettings.${name} [ "enable" ];
          secretPath = config.age.secrets.${provider.secret}.path;
        }
      ) (lib.filterAttrs (name: _provider: agentSettings.${name}.enable) providers);

  # Agents with a global model choice declare one default among their providers.
  defaultProvider =
    selected:
    lib.findSingle (name: selected.${name}.agentConfig.default or false)
      (throw "agents: select one default provider in the agent settings")
      (throw "agents: multiple providers are marked as default in the agent settings")
      (builtins.attrNames selected);

  # Secrets stay encrypted in the store; adapters read their paths at runtime.
  ageSecrets =
    selected:
    lib.listToAttrs (
      map (
        provider:
        lib.nameValuePair provider.secret {
          file = ../../secrets + "/${provider.secret}.age";
        }
      ) (lib.attrValues selected)
    );
}
