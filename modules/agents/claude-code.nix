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

      mkClaudecodeWrapper =
        baseUrl: model: smallModel: apiKeyPath: name: effortLevel:
        pkgs.writeShellScriptBin name ''
          export ANTHROPIC_BASE_URL="${baseUrl}"
          export ANTHROPIC_MODEL="${model}"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="${model}"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="${model}"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="${smallModel}"
          export CLAUDE_CODE_SUBAGENT_MODEL="${smallModel}"
          ${lib.optionalString (effortLevel != "") "export CLAUDE_CODE_EFFORT_LEVEL=\"${effortLevel}\""}
          export API_TIMEOUT_MS="1200000"
          export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
          if [ -r "${apiKeyPath}" ]; then
            export ANTHROPIC_AUTH_TOKEN="$(cat "${apiKeyPath}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.claude-code} "$@"
        '';

      mkClaudecodeWrappers =
        providerName: provider:
        let
          agentConfig = provider.agents.claudeCode;
          smallModelId =
            provider.models.${agentConfig.smallModel}.anthropicId
              or provider.models.${agentConfig.smallModel}.id;
        in
        lib.mapAttrsToList (
          modelName: model:
          mkClaudecodeWrapper provider.endpoints.anthropic (model.anthropicId or model.id) smallModelId
            provider.secret.path
            "cc-${providerName}-${modelName}"
            (agentConfig.effortLevel or "")
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
