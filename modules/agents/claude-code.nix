{
  flake.modules.home."agents/claude-code" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_context.nix {
        inherit config lib;
        settings = (import ./_agents.nix).claudeCode;
      };

      mkClaudecodeWrappers =
        providerName: provider:
        let
          agentConfig = provider.agentConfig;
          effortLevel = agentConfig.effortLevel or "";
          smallModel = provider.models.${agentConfig.smallModel or provider.defaultModelKey};
        in
        lib.mapAttrsToList (
          modelName: model:
          pkgs.writeShellScriptBin "cc-${providerName}-${modelName}" ''
            set -e
            export ANTHROPIC_BASE_URL="${provider.endpoints.anthropic}"
            export ANTHROPIC_MODEL="${model.id}"
            export ANTHROPIC_DEFAULT_OPUS_MODEL="${model.id}"
            export ANTHROPIC_DEFAULT_SONNET_MODEL="${model.id}"
            export ANTHROPIC_DEFAULT_HAIKU_MODEL="${smallModel.id}"
            export CLAUDE_CODE_SUBAGENT_MODEL="${smallModel.id}"
            export CLAUDE_CODE_MAX_CONTEXT_TOKENS="${toString model.limit.context}"
            ${lib.optionalString (effortLevel != "") "export CLAUDE_CODE_EFFORT_LEVEL=\"${effortLevel}\""}
            export API_TIMEOUT_MS="1200000"
            export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
            apiKey="$(cat "${provider.secretPath}")"
            export ANTHROPIC_AUTH_TOKEN="$apiKey"
            exec ${lib.getExe pkgs.llm-agents.claude-code} "$@"
          ''
        ) provider.models;
    in
    {
      home.packages = [
        pkgs.llm-agents.claude-code
      ]
      ++ lib.concatLists (lib.mapAttrsToList mkClaudecodeWrappers providers.selected);

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

      age.secrets = providers.ageSecrets;
    };
}
