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
        volcengine-codingplan-api-key
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

      # Volcengine Ark Coding Plan's OpenAI-compatible Responses API. Codex
      # joins base_url to `/responses`. Use the /api/coding/v3 path (not
      # /api/v3) so requests consume the Coding Plan quota.
      # https://docs.volcengine.com/docs/82379/2556056
      volceBaseUrl = "https://ark.cn-beijing.volces.com/api/coding/v3";

      # Local self-hosted GPU Responses router. Codex joins base_url to
      # `/responses`.
      codexGpuBaseUrl = "http://172.18.36.44:8000/v1";

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

      # Volcengine Coding Plan models. Volcengine publishes no official codex
      # catalog, so this static file mirrors the deepseek catalog's structure
      # (the Codex system prompt is generic, not provider-specific). Reasoning
      # effort is low/medium/high per the doc.
      # https://docs.volcengine.com/docs/82379/2556056
      codexVolceModelsJson = ./codex-volce-models.json;

      readSecret =
        name: secret:
        pkgs.writeShellScript "read-${name}" ''
          [ -r "${secret.path}" ] || exit 1
          value="$(<"${secret.path}")"
          printf '%s' "$value"
        '';

      # Base config shared by the TUI and Desktop. Provider definitions live
      # here so the separate profile files only select a model/provider/catalog.
      codexConfig = pkgs.writeText "codex-config.toml" ''
        model = "gpt-5.6-terra"
        model_provider = "openai"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"

        [model_providers.opencode-go]
        name = "OpenCode Go"
        base_url = "${opencodeGoBaseUrl}"
        wire_api = "responses"
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        [model_providers.opencode-go.auth]
        command = "${readSecret "opencode-go-api-key" opencode-go-api-key}"

        [model_providers.deepseek]
        name = "DeepSeek"
        base_url = "${deepseekBaseUrl}"
        wire_api = "responses"
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        [model_providers.deepseek.auth]
        command = "${readSecret "deepseek-api-key" deepseek-api-key}"

        [model_providers.volcengine-coding-plan]
        name = "volcengine-coding-plan"
        base_url = "${volceBaseUrl}"
        wire_api = "responses"
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        [model_providers.volcengine-coding-plan.auth]
        command = "${readSecret "volcengine-codingplan-api-key" volcengine-codingplan-api-key}"

        [model_providers.codex-gpu]
        name = "Codex GPU"
        base_url = "${codexGpuBaseUrl}"
        experimental_bearer_token = "8b964310965445819bfd028144ba7cb34676c7f33c97c73966050fb59e903bd5"
        wire_api = "responses"
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
      '';

      codexGoConfig = pkgs.writeText "codex-go.config.toml" ''
        model = "gpt-5.6-luna"
        model_provider = "opencode-go"
        model_catalog_json = "${codexGoModelsJson}"
      '';

      codexDsConfig = pkgs.writeText "codex-ds.config.toml" ''
        model = "deepseek-v4-pro"
        model_provider = "deepseek"
        model_catalog_json = "${codexDsModelsJson}"
      '';

      codexVolceConfig = pkgs.writeText "codex-volce.config.toml" ''
        model = "glm-5.3"
        model_provider = "volcengine-coding-plan"
        model_catalog_json = "${codexVolceModelsJson}"
      '';

      codexGpuConfig = pkgs.writeText "codex-gpu.config.toml" ''
        model = "qwen3.8-27b"
        model_provider = "codex-gpu"
      '';

      # Official binary: stock codex with its own CODEX_HOME.
      codex = pkgs.writeShellScriptBin "codex" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';

      # Provider commands use profiles over Codex's normal CODEX_HOME, so
      # `codex`, `codex-go`, and `codex-ds` share one session store. Codex's
      # native resume picker filters by active model_provider.
      codexGo = pkgs.writeShellScriptBin "codex-go" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} --profile codex-go "$@"
      '';

      codexDs = pkgs.writeShellScriptBin "codex-ds" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} --profile codex-ds "$@"
      '';

      codexVolce = pkgs.writeShellScriptBin "codex-volce" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} --profile codex-volce "$@"
      '';

      codexGpu = pkgs.writeShellScriptBin "codex-gpu" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} --profile codex-gpu "$@"
      '';

    in
    {
      # Four binaries, one shared Codex session store:
      #   codex       - official OpenAI models (stock bundled catalog)
      #   codex-go    - gpt-5.6-luna via OpenCode Go
      #   codex-ds    - deepseek-v4-flash/pro via DeepSeek
      #   codex-volce - glm-5.3 + others via Volcengine Coding Plan
      #   codex-gpu   - qwen3.8-27b via local GPU Responses router
      home.packages = [
        codex
        codexGo
        codexDs
        codexVolce
        codexGpu
      ];

      # Force the declarative base and profile templates over runtime changes.
      # Remove first so stale read-only store symlinks from an older generation
      # can't block the writes.
      home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfgDir="${config.xdg.configHome}/codex"
        mkdir -p "$cfgDir"
        # ChatGPT Desktop's bundled Codex defaults to ~/.codex; point it at the
        # shared XDG dir so desktop and CLI share config/sessions. Move any real
        # directory aside rather than deleting it.
        if [ -e "$HOME/.codex" ] && [ ! -L "$HOME/.codex" ]; then
          mv "$HOME/.codex" "$HOME/.codex.bak.$(date +%s)"
        fi
        ln -sfn "$cfgDir" "$HOME/.codex"
        rm -f "$cfgDir/config.toml" "$cfgDir/codex-go.config.toml" "$cfgDir/codex-ds.config.toml" "$cfgDir/codex-volce.config.toml" "$cfgDir/codex-gpu.config.toml"
        install -m 0644 ${codexConfig} "$cfgDir/config.toml"
        install -m 0644 ${codexGoConfig} "$cfgDir/codex-go.config.toml"
        install -m 0644 ${codexDsConfig} "$cfgDir/codex-ds.config.toml"
        install -m 0644 ${codexVolceConfig} "$cfgDir/codex-volce.config.toml"
        install -m 0644 ${codexGpuConfig} "$cfgDir/codex-gpu.config.toml"
      '';

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
        opencode-go-api-key.file = ../../secrets/opencode-go-api-key.age;
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
