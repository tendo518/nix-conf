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
      # DSH resolves this shared store before launch environment, so seeding it
      # makes the CLI and Desktop app use the same agenix-managed credentials.
      credentialFile = "${config.home.homeDirectory}/.dsh/.credentials.yaml";
      credentialSyncLines = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: provider: ''
          if [ -r "${provider.secretPath}" ]; then
            key="$(${pkgs.coreutils}/bin/cat "${provider.secretPath}")"
            if [ -n "$key" ]; then
              export ${apiKeyEnv name}="$key"
              ${pkgs.yq-go}/bin/yq -i '.version = 1 | .refs.${apiKeyEnv name} = strenv(${apiKeyEnv name})' "${credentialFile}" 2>/dev/null
              unset ${apiKeyEnv name}
            fi
          fi
        '') selected
      );
      syncDshCredentials = pkgs.writeShellScript "dsh-sync-credentials" ''
        set -e
        umask 077
        mkdir -p "$(${pkgs.coreutils}/bin/dirname "${credentialFile}")"
        if [ ! -s "${credentialFile}" ]; then
          printf 'version: 1\n' > "${credentialFile}"
        fi
        chmod 600 "${credentialFile}"
        ${credentialSyncLines}
        chmod 600 "${credentialFile}"
      '';
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
      thinkingLevels = [
        "off"
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
        "max"
      ];
      effortValues =
        model:
        lib.concatMap (option: option.values or [ ]) (
          lib.filter (option: option.type == "effort") (model.reasoning_options or [ ])
        );
      reasoningEfforts =
        model:
        let
          efforts = effortValues model;
        in
        # DSH accepts a wire value for every offered level. Omit unsupported
        # levels instead of sending null, which its resolver rejects.
        lib.optionalAttrs (builtins.elem "none" efforts) { off = "none"; }
        // lib.genAttrs (lib.filter (level: builtins.elem level efforts) (lib.tail thinkingLevels)) (
          level: level
        );

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
              compat = lib.optionalAttrs ((provider.agentConfig.api or "openai-completions") == "openai-completions") {
                supportsReasoningEffort = true;
                thinkingFormat = provider.thinkingFormat or "openai";
              };
              models = map (
                model:
                (modelConfig model)
                // {
                  input = inputTypes model;
                }
                // lib.optionalAttrs (model ? reasoning_options) {
                  reasoningEfforts = reasoningEfforts model;
                }
              ) (lib.attrValues provider.models);
            }) (builtins.removeAttrs selected [ "deepseek" ]);
          }
        ];
    in
    {
      home.packages = [
        pkgs.llm-agents.dsh
        pkgs.pnpm # needed for dsh plugin
      ];

      # Home-level patches apply to every profile; JSON is also valid YAML.
      home.file.".dsh/cordis.patch.yml".text = builtins.toJSON patches;

      home.activation.setupDshCredentials = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${syncDshCredentials}
      '';

      age.secrets = providers.ageSecrets;
    };
}
