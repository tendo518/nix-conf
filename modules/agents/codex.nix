{
  flake.modules.home."agents/codex" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets) volcengine-codingplan-api-key;

      # Volces coding plan exposes two endpoints:
      #   /api/coding     - Anthropic Messages API
      #   /api/coding/v3  - OpenAI Responses API
      # Codex speaks OpenAI's Responses wire format, so we point at /v3.
      volcesBaseUrl = "https://ark.cn-beijing.volces.com/api/coding/v3";

      # Model id -> Volces API model name. Mirrors `providers.volces.models`
      # in modules/agents/claude-code.nix so wrapper names stay in sync.
      models = {
        kimi_k2_6 = "kimi-k2.6";
        glm_5_2 = "glm-5.2";
        minimax_m3 = "minimax-m3";
        ds_v4pro = "deepseek-v4-pro";
        ds_v4flash = "deepseek-v4-flash";
      };

      # Model metadata catalog so codex doesn't fall back to degraded defaults
      # for custom-provider models.  Referenced from config.toml via
      # model_catalog_json.  Context windows are approximate; tune as needed.
      mkModelEntry =
        slug: contextWindow: displayName: reasoningEfforts:
        let
          mid = builtins.length reasoningEfforts / 2;
        in
        {
          inherit slug;
          display_name = displayName;
          description = "${displayName} via Volces Coding Plan";
          context_window = contextWindow;
          max_context_window = contextWindow;
          effective_context_window_percent = 90;
          input_modalities = [ "text" ];
          default_reasoning_level =
            if reasoningEfforts == [ ] then null else builtins.elemAt reasoningEfforts mid;
          supported_reasoning_levels = builtins.map (e: { effort = e; description = ""; }) reasoningEfforts;
          supports_reasoning_summaries = false;
          default_reasoning_summary = "none";
          support_verbosity = false;
          default_verbosity = "low";
          supports_parallel_tool_calls = true;
          supports_image_detail_original = false;
          supports_search_tool = false;
          shell_type = "shell_command";
          apply_patch_tool_type = "freeform";
          web_search_tool_type = "none";
          visibility = "list";
          supported_in_api = true;
          priority = 0;
          additional_speed_tiers = [ ];
          service_tiers = [ ];
          upgrade = null;
          use_responses_lite = false;
          model_messages = null;
          truncation_policy = {
            mode = "percent";
            limit = 90;
          };
        };

      modelCatalog = pkgs.writeText "codex-model-catalog.json" (
        builtins.toJSON {
          models = [
            (mkModelEntry "deepseek-v4-flash" 1000000 "DeepSeek V4 Flash" [
              "minimal"
              "low"
              "medium"
              "high"
              "xhigh"
            ])
            (mkModelEntry "deepseek-v4-pro" 1000000 "DeepSeek V4 Pro" [
              "minimal"
              "low"
              "medium"
              "high"
              "xhigh"
            ])
            (mkModelEntry "kimi-k2.6" 262144 "Kimi K2.6" [
              "low"
              "medium"
              "high"
            ])
            (mkModelEntry "glm-5.2" 1000000 "GLM 5.2" [
              "low"
              "medium"
              "high"
            ])
            (mkModelEntry "minimax-m3" 1000000 "MiniMax M3" [
              "low"
              "medium"
              "high"
            ])
          ];
        }
      );

      # Seeded on first activation. After that, the file is owned by the user
      # so Codex can persist things like `projects.<path>.trust_level` without
      # hitting the read-only /nix/store. Delete it to re-seed from Nix.
      #
      # Pre-trusts the user's home directory so the "trust this folder?"
      # prompt never appears for projects under ~. Command approval is left
      # at `on-request` so tool calls still get explicit user consent.
      codexConfig = pkgs.writeText "codex-config.toml" ''
        model = "deepseek-v4-flash"
        model_provider = "volces"
        model_catalog_json = "${modelCatalog}"
        approval_policy = "on-request"
        sandbox_mode = "workspace-write"

        [model_providers.volces]
        name = "Volces Coding Plan"
        base_url = "${volcesBaseUrl}"
        env_key = "VOLCENGINE_API_KEY"
        wire_api = "responses"
        requires_openai_auth = false

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
      '';

      mkCodexExec = modelFlag: name: ''
        if [ -r "${volcengine-codingplan-api-key.path}" ]; then
          export VOLCENGINE_API_KEY="$(cat "${volcengine-codingplan-api-key.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.codex} ${modelFlag} "$@"
      '';

      codexVolces = pkgs.writeShellScriptBin "codex-volces" (mkCodexExec "" "codex-volces");

      codexVolcesModel =
        key: model:
        pkgs.writeShellScriptBin "codex-volces-${key}" (mkCodexExec "--model \"${model}\"" "codex-volces-${key}");

      codexModelWrappers = lib.mapAttrsToList codexVolcesModel models;

    in
    {
      home.packages = [ codexVolces ] ++ codexModelWrappers;

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
      };
    };
}
