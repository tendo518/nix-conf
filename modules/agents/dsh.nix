{
  flake.modules.home."agents/dsh" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_context.nix {
        inherit config lib;
        settings = (import ./_agents.nix).dsh;
      };
      inherit (providers) selected;
      apiKeyEnv = name: "${lib.toUpper name}_API_KEY";
      modelConfig =
        model:
        {
          inherit (model) id name;
          contextWindow = model.limit.context;
        }
        // lib.optionalAttrs (model.limit ? output) {
          maxTokens = model.limit.output;
        };
      inputTypes = model: lib.intersectLists [ "text" "image" ] model.modalities.input;

      # The native adapter owns DeepSeek's protocol and reasoning controls.
      # Leave agent-default-model unpatched so the picker can save selections.
      patches =
        lib.optional (selected ? deepseek) {
          id = "llm-deepseek";
          config = {
            apiKeyEnv = apiKeyEnv "deepseek";
            baseURL = selected.deepseek.endpoints.anthropic;
            models = map (
              model:
              (modelConfig model)
              // {
                inputModalities = inputTypes model;
              }
            ) (lib.attrValues selected.deepseek.models);
          };
        }
        ++ [
          {
            id = "llm-pi-ai";
            config.providers = lib.mapAttrs (name: provider: {
              displayName = provider.name;
              apiKeyEnv = apiKeyEnv name;
              baseURL = provider.endpoints.openai;
              api = provider.agentConfig.api or "openai-completions";
              models = map (
                model:
                (modelConfig model)
                // {
                  input = inputTypes model;
                }
              ) (lib.attrValues provider.models);
            }) (builtins.removeAttrs selected [ "deepseek" ]);
          }
        ];
      dshWrapped = pkgs.writeShellScriptBin "dsh" ''
        set -e
        : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: provider: ''
            ${apiKeyEnv name}="$(${pkgs.coreutils}/bin/cat "${provider.secretPath}")"
            export ${apiKeyEnv name}
          '') selected
        )}
        exec ${lib.getExe pkgs.llm-agents.dsh} "$@"
      '';
    in
    {
      home.packages = [
        dshWrapped
        pkgs.pnpm # needed for dsh plugin
      ];

      # Home-level patches apply to every profile; JSON is also valid YAML.
      home.file.".dsh/cordis.patch.yml".text = builtins.toJSON patches;

      age.secrets = providers.ageSecrets;
    };
}
