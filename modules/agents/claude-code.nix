{
  flake.modules.home."agents/claude-code" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_providers.nix { inherit config lib; };
      selected = providers.selectProviders "claudeCode";

      # Allow near-million windows that reserve a small part of the context.
      claudeModelId = model: model.id + lib.optionalString (model.contextWindow >= 950000) "[1m]";

      mkClaudecodeWrappers =
        providerName: provider:
        let
          agentConfig = provider.agentConfig;
          effortLevel = agentConfig.effortLevel or "";
          smallModel = provider.models.${agentConfig.smallModel or provider.defaultModel};
          smallModelId = claudeModelId smallModel;
          apiKeyPath = provider.secretPath;
        in
        lib.mapAttrsToList (
          modelName: model:
          let
            modelId = claudeModelId model;
          in
          pkgs.writeShellScriptBin "cc-${providerName}-${modelName}" ''
            set -e
            export ANTHROPIC_BASE_URL="${provider.endpoints.anthropic}"
            export ANTHROPIC_MODEL="${modelId}"
            export ANTHROPIC_DEFAULT_OPUS_MODEL="${modelId}"
            export ANTHROPIC_DEFAULT_SONNET_MODEL="${modelId}"
            export ANTHROPIC_DEFAULT_HAIKU_MODEL="${smallModelId}"
            export CLAUDE_CODE_SUBAGENT_MODEL="${smallModelId}"
            ${lib.optionalString (effortLevel != "") "export CLAUDE_CODE_EFFORT_LEVEL=\"${effortLevel}\""}
            export API_TIMEOUT_MS="1200000"
            export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
            apiKey="$(cat "${apiKeyPath}")"
            export ANTHROPIC_AUTH_TOKEN="$apiKey"
            exec ${lib.getExe pkgs.llm-agents.claude-code} "$@"
          ''
        ) provider.models;

      claudecodeWrappers = lib.concatLists (lib.mapAttrsToList mkClaudecodeWrappers selected);

      # Third-party model IDs are absent from the Claude Code catalog, so an
      # unmapped session logs an "isn't described by this version's model
      # catalog" notice, emits the [claude-code:unrecognized_model] diagnostic
      # line, and handles prompts as an unrecognized model. `modelPicker` rows
      # with `behavesAs` map each ID onto a built-in model whose client-side
      # handling applies instead; the ID sent to the provider is unchanged.
      pickerOptions = lib.unique (
        lib.concatMap (
          provider:
          map (model: {
            model = claudeModelId model;
            label = model.displayName;
            behavesAs = model.claudeBehavesAs;
          }) (lib.filter (model: model ? claudeBehavesAs) (lib.attrValues provider.models))
        ) (lib.attrValues selected)
      );
    in
    {
      home.packages = [ pkgs.llm-agents.claude-code ] ++ claudecodeWrappers;

      home.activation.setupClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.claude"
        cp ${
          pkgs.writeText "claude-settings.json" (
            builtins.toJSON {
              statusLine = {
                type = "command";
                command = "${lib.getExe pkgs.llm-agents.ccstatusline}";
                padding = 0;
              };
              skipWebFetchPreflight = true;
              theme = "auto";
              modelPicker.options = pickerOptions;
            }
          )
        } "$HOME/.claude/settings.json"
        chmod u+w "$HOME/.claude/settings.json"
      '';

      age.secrets = providers.ageSecrets selected;
    };
}
