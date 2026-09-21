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

      mkClaudecodeWrappers =
        providerName: provider:
        let
          agentConfig = provider.agents.claudeCode;
          effortLevel = agentConfig.effortLevel or "";
          smallModel = provider.models.${agentConfig.smallModel};
          smallModelId = smallModel.anthropicId or smallModel.id;
          apiKeyPath = config.age.secrets.${provider.secret}.path;
        in
        lib.mapAttrsToList (
          modelName: model:
          let
            modelId = model.anthropicId or model.id;
          in
          pkgs.writeShellScriptBin "cc-${providerName}-${modelName}" ''
            export ANTHROPIC_BASE_URL="${provider.endpoints.anthropic}"
            export ANTHROPIC_MODEL="${modelId}"
            export ANTHROPIC_DEFAULT_OPUS_MODEL="${modelId}"
            export ANTHROPIC_DEFAULT_SONNET_MODEL="${modelId}"
            export ANTHROPIC_DEFAULT_HAIKU_MODEL="${smallModelId}"
            export CLAUDE_CODE_SUBAGENT_MODEL="${smallModelId}"
            ${lib.optionalString (effortLevel != "") "export CLAUDE_CODE_EFFORT_LEVEL=\"${effortLevel}\""}
            export API_TIMEOUT_MS="1200000"
            export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
            if [ -r "${apiKeyPath}" ]; then
              export ANTHROPIC_AUTH_TOKEN="$(cat "${apiKeyPath}")"
            fi
            exec ${lib.getExe pkgs.llm-agents.claude-code} "$@"
          ''
        ) provider.models;

      claudecodeWrappers = lib.concatLists (lib.mapAttrsToList mkClaudecodeWrappers selected);
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
            }
          )
        } "$HOME/.claude/settings.json"
        chmod u+w "$HOME/.claude/settings.json"
      '';

      age.secrets = providers.ageSecrets selected;
    };
}
