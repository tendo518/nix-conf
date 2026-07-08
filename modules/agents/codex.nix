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
        kimi_k2_7_code = "kimi-k2.7-code";
        glm_5_2 = "glm-5.2";
        minimax_m3 = "minimax-m3";
        ds_v4pro = "deepseek-v4-pro";
        ds_v4flash = "deepseek-v4-flash";
      };

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
        approval_policy = "on-request"
        sandbox_mode = "workspace-write"

        [model_providers.volces]
        name = "Volces Coding Plan"
        base_url = "${volcesBaseUrl}"
        env_key = "VOLCENGINE_API_KEY"
        wire_api = "responses"
        requires_openai_auth = false
        stream_idle_timeout_ms = 600000
        request_max_retries = 6

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
        pkgs.writeShellScriptBin "codex-volces-${key}" (
          mkCodexExec "--model \"${model}\"" "codex-volces-${key}"
        );

      codexModelWrappers = lib.mapAttrsToList codexVolcesModel models;

      # Raw Codex: override the config.toml's model_provider back to Codex's
      # built-in "openai" default so `codex` uses its own models rather than
      # routing through Volces. No VOLCENGINE_API_KEY export — the user
      # authenticates via `codex login` or OPENAI_API_KEY.
      codexRaw = pkgs.writeShellScriptBin "codex" ''
        exec ${lib.getExe pkgs.llm-agents.codex} -c model_provider=openai "$@"
      '';

    in
    {
      home.packages = [
        codexRaw
        codexVolces
      ]
      ++ codexModelWrappers;

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
