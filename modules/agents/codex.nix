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
        volcengine-codingplan-api-key
        deepseek-api-key
        ;

      # Volces coding plan exposes two endpoints:
      #   /api/coding     - Anthropic Messages API
      #   /api/coding/v3  - OpenAI Responses API
      # Codex speaks OpenAI's Responses wire format, so we point at /v3.
      volcesBaseUrl = "https://ark.cn-beijing.volces.com/api/coding/v3";

      # DeepSeek's native Responses API. base_url matches the official Codex
      # integration guide; codex joins it to `/responses`.
      # https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/codex
      deepseekBaseUrl = "https://api.deepseek.com/";

      # Model id -> API model name per provider. Mirrors `providers.*.models`
      # in modules/agents/claude-code.nix so wrapper names stay in sync.
      # DeepSeek's Responses API currently exposes only deepseek-v4-flash
      # (v4-pro is planned for early August 2026); add it here once enabled.
      volcesModels = {
        kimi_k2_6 = "kimi-k2.6";
        kimi_k2_7_code = "kimi-k2.7-code";
        glm_5_2 = "glm-5.2";
        minimax_m3 = "minimax-m3";
        ds_v4pro = "deepseek-v4-pro";
        ds_v4flash = "deepseek-v4-flash";
      };

      deepseekModels = {
        ds_v4flash = "deepseek-v4-flash";
      };

      # DeepSeek-only model catalog, vendored from DeepSeek's official Codex
      # setup (flash entry only; v4-pro is omitted until the API supports it).
      # Pointing model_catalog_json at this replaces codex's built-in GPT list
      # so the model picker shows only deepseek-v4-flash.
      deepseekModelsJson = ./codex-deepseek-models.json;

      # Seeded on first activation. After that, the file is owned by the user
      # so Codex can persist things like `projects.<path>.trust_level` without
      # hitting the read-only /nix/store. Delete it to re-seed from Nix.
      #
      # Pre-trusts the user's home directory so the "trust this folder?"
      # prompt never appears for projects under ~. Command approval is left
      # at `on-request` so tool calls still get explicit user consent.
      codexConfig = pkgs.writeText "codex-config.toml" ''
        # Defaults for the bare `codex` wrapper: user's ChatGPT subscription
        # (openai provider), gpt-5.6-terra at medium reasoning. Provider/model
        # wrappers override these per command.
        model = "gpt-5.6-terra"
        model_provider = "openai"
        model_reasoning_effort = "medium"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"

        [model_providers.volces]
        name = "Volces Coding Plan"
        base_url = "${volcesBaseUrl}"
        env_key = "VOLCENGINE_API_KEY"
        wire_api = "responses"
        requires_openai_auth = false
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

        # DeepSeek's official Codex guide uses `experimental_bearer_token` with
        # a literal key; we use `env_key` instead so the agenix-managed secret
        # is read at runtime by the codex-deepseek wrapper, not baked into the
        # (world-buildable) config. Same Bearer auth, matches the volces provider.
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

      # Build a `codex-<provider>` wrapper plus one `codex-<provider>-<key>` per
      # model that overrides --model. Each wrapper exports the provider's API
      # key and forces model_provider via -c so it never depends on the
      # config.toml default.
      #
      # `defaultModel` is the model the bare `codex-<provider>` wrapper pins.
      # Pass "" to fall through to config.toml's `model` (volces keeps the
      # user's configured default); pass a concrete model to pin it. DeepSeek
      # pins because its only model differs from the shared config default.
      #
      # `extraFlags` are extra `-c` overrides added to every wrapper for this
      # provider. DeepSeek pins its own model catalog (model_catalog_json, which
      # replaces codex's built-in GPT list so the picker shows only
      # deepseek-v4-flash) and forces reasoning effort `high`: the global config
      # default is `medium`, which deepseek-v4-flash does not support (its
      # catalog declares low/high/max) — matching DeepSeek's official codex
      # guide. Volces passes none and inherits the config defaults.
      mkProviderWrappers =
        provider: envKey: apiKeyPath: defaultModel: extraFlags: models:
        let
          mkExec = model: ''
            if [ -r "${apiKeyPath}" ]; then
              export ${envKey}="$(cat "${apiKeyPath}")"
            fi
            exec ${lib.getExe pkgs.llm-agents.codex} -c model_provider=${provider} ${extraFlags} ${lib.optionalString (model != "") "--model \"${model}\""} "$@"
          '';
          default = pkgs.writeShellScriptBin "codex-${provider}" (mkExec defaultModel);
          perModel = lib.mapAttrsToList (
            key: model: pkgs.writeShellScriptBin "codex-${provider}-${key}" (mkExec model)
          ) models;
        in
        [ default ] ++ perModel;

      codexVolcesWrappers = mkProviderWrappers "volces" "VOLCENGINE_API_KEY"
        volcengine-codingplan-api-key.path "" "" volcesModels;
      codexDeepseekWrappers = mkProviderWrappers "deepseek" "DEEPSEEK_API_KEY"
        deepseek-api-key.path "deepseek-v4-flash"
        "-c model_catalog_json=${deepseekModelsJson} -c model_reasoning_effort=high" deepseekModels;

      # Raw Codex: override the config.toml's model_provider back to Codex's
      # built-in "openai" default so `codex` uses its own models rather than
      # routing through a third party. No API key export - the user
      # authenticates via `codex login` or OPENAI_API_KEY.
      codexRaw = pkgs.writeShellScriptBin "codex" ''
        exec ${lib.getExe pkgs.llm-agents.codex} -c model_provider=openai "$@"
      '';

    in
    {
      home.packages = [
        codexRaw
      ]
      ++ codexVolcesWrappers
      ++ codexDeepseekWrappers;

      # xdg.configFile would symlink config.toml into /nix/store (read-only),
      # which makes Codex's trust prompts fail with `config/batchWrite failed`
      # because it can't persist the trust entry. Seed a real file instead and
      # leave it alone on subsequent rebuilds so user-added entries survive.
      home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.xdg.configHome}/codex"
        if [ ! -e "${config.xdg.configHome}/codex/config.toml" ]; then
          install -m 0644 ${codexConfig} "${config.xdg.configHome}/codex/config.toml"
        fi
      '';

      age.secrets = {
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
      };
    };
}
