{ config, lib }:
let
  providers = import ./_providers;
in
{
  # Models keep the same fields for every agent; adapters translate them.
  selectProviders =
    agent:
    lib.mapAttrs
      (
        _name: provider:
        builtins.removeAttrs provider [ "agents" ]
        // {
          agentConfig = provider.agents.${agent};
          secretPath = config.age.secrets.${provider.secret}.path;
        }
      )
      (
        lib.filterAttrs (
          _name: provider:
          (provider.enable or true) && provider.agents ? ${agent} && (provider.agents.${agent}.enable or true)
        ) providers
      );

  # Agents with a global model choice declare one default among their providers.
  defaultProvider =
    selected:
    lib.findSingle (name: selected.${name}.agentConfig.default or false)
      (throw "agents: select a default provider with agents.<agent>.default = true")
      (throw "agents: multiple providers are marked as the default for one agent")
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
