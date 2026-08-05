{
  flake.modules.home."agents/codex" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets)
        deepseek-api-key
        opencode-go-api-key
        ;

      # DeepSeek's native Responses API. base_url matches the official Codex
      # integration guide; codex joins it to `/responses`.
      # https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/codex
      deepseekBaseUrl = "https://api.deepseek.com/";

      # OpenCode Go's Responses API. Codex joins base_url to `/responses`, so
      # the base points at the `/v1` prefix (docs: opencode.ai/docs/zh-cn/go).
      # Console Go only exposes gpt-5.6-luna over `/v1/responses`; its other
      # models (including deepseek) are chat-completions only, which codex
      # can't speak - hence one binary per provider.
      opencodeGoBaseUrl = "https://opencode.ai/zen/go/v1";

      # One catalog per third-party provider. model_catalog_json replaces
      # codex's bundled catalog, so each binary's /model only lists that
      # provider's models and the provider is always the right one.
      #
      # gpt-5.6-luna (codex-go): opencode-go proxies it through its Responses
      # gateway; the entry keeps it selectable with proper metadata.
      codexGoModelsJson = ./codex-go-models.json;

      # DeepSeek entries vendored verbatim from DeepSeek's official Codex
      # setup (api-docs.deepseek.com/.../codex + the bundled
      # codex-deepseek-setup.sh). DeepSeek needs catalog entries because codex
      # doesn't know deepseek-v4-* natively and would otherwise send its
      # default reasoning effort (medium), which DeepSeek rejects. The catalog
      # declares the supported levels (low/high/max, default high) so codex
      # picks a valid effort.
      codexDsModelsJson = ./codex-deepseek-models.json;

      # Official binary config: stock bundled model catalog, ChatGPT
      # subscription only. No model_catalog_json, so /model keeps every model
      # codex ships. Replaced from Nix on every activation.
      codexConfig = pkgs.writeText "codex-config.toml" ''
        model = "gpt-5.6-terra"
        model_provider = "openai"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
      '';

      # gpt-5.6-luna via OpenCode Go (Console Go's Responses endpoint).
      codexGoConfig = pkgs.writeText "codex-go-config.toml" ''
        model = "gpt-5.6-luna"
        model_provider = "opencode-go"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"

        model_catalog_json = "${codexGoModelsJson}"

        [model_providers.opencode-go]
        name = "OpenCode Go"
        base_url = "${opencodeGoBaseUrl}"
        env_key = "OPENCODE_GO_API_KEY"
        wire_api = "responses"
        requires_openai_auth = false
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
      '';

      # DeepSeek V4 Flash/Pro via DeepSeek's own Responses API. Console Go
      # serves these over chat completions only, which codex can't use, so
      # they get their own binary/provider.
      codexDsConfig = pkgs.writeText "codex-ds-config.toml" ''
        model = "deepseek-v4-flash"
        model_provider = "deepseek"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"

        model_catalog_json = "${codexDsModelsJson}"

        # DeepSeek's official Codex guide uses `experimental_bearer_token` with
        # a literal key; we use `env_key` instead so the agenix-managed secret
        # is read at runtime by the codex-ds wrapper, not baked into the
        # (world-buildable) config.
        [model_providers.deepseek]
        name = "DeepSeek"
        base_url = "${deepseekBaseUrl}"
        env_key = "DEEPSEEK_API_KEY"
        wire_api = "responses"
        requires_openai_auth = false
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
      '';

      # Official binary: stock codex with its own CODEX_HOME.
      codex = pkgs.writeShellScriptBin "codex" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';

      # One wrapper per third-party provider, each with its own CODEX_HOME so
      # config, auth, and history stay isolated.
      codexGo = pkgs.writeShellScriptBin "codex-go" ''
        if [ -r "${opencode-go-api-key.path}" ]; then
          export OPENCODE_GO_API_KEY="$(cat "${opencode-go-api-key.path}")"
        fi
        export CODEX_HOME="${config.xdg.configHome}/codex-go"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';

      codexDs = pkgs.writeShellScriptBin "codex-ds" ''
        if [ -r "${deepseek-api-key.path}" ]; then
          export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
        fi
        export CODEX_HOME="${config.xdg.configHome}/codex-ds"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';

    in
    {
      # Three binaries, one provider each:
      #   codex    - official OpenAI models (stock bundled catalog)
      #   codex-go - gpt-5.6-luna via OpenCode Go
      #   codex-ds - deepseek-v4-flash/pro via DeepSeek
      home.packages = [
        codex
        codexGo
        codexDs
      ];

      # Force the declarative template over any runtime changes codex made.
      # rm first so a stale read-only store symlink from an older generation
      # can't block the write.
      home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="${config.xdg.configHome}/codex/config.toml"
        mkdir -p "$(dirname "$cfg")"
        rm -f "$cfg"
        install -m 0644 ${codexConfig} "$cfg"
      '';

      home.activation.setupCodexGoConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="${config.xdg.configHome}/codex-go/config.toml"
        mkdir -p "$(dirname "$cfg")"
        rm -f "$cfg"
        install -m 0644 ${codexGoConfig} "$cfg"
      '';

      home.activation.setupCodexDsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="${config.xdg.configHome}/codex-ds/config.toml"
        mkdir -p "$(dirname "$cfg")"
        rm -f "$cfg"
        install -m 0644 ${codexDsConfig} "$cfg"
      '';

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
        opencode-go-api-key.file = ../../secrets/opencode-go-api-key.age;
      };
    };
}
