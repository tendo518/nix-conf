{
  flake.modules.home."agents/reasonix" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets) deepseek-api-key;

      # --- Shared config fragments ---

      providerSection = ''
        [[providers]]
        name           = "deepseek"
        kind           = "openai"
        base_url       = "https://api.deepseek.com"
        models         = ["deepseek-v4-flash", "deepseek-v4-pro"]
        default        = "deepseek-v4-pro"
        api_key_env    = "DEEPSEEK_API_KEY"
        context_window = 1000000
        effort         = "max"
      '';

      baseConfig = ''
        default_model = "deepseek"
        language = "zh"

        [ui]
        theme = "auto"

        [notifications]
        enabled          = true
        turn_done        = true
        approval_request = true
        ask_request      = true

        ${providerSection}

        [codegraph]
        enabled      = true
        auto_install = false
      '';

      # --- Single-model config (no planner) ---
      # Written to ~/.reasonix/config.toml; used by bare `reasonix`.
      singleModelConfig = ''
        ${baseConfig}

        [agent]
      '';

      # --- Two-model config (planner + executor) ---
      # `planner_model` activates the coordinator: the planner runs in its own
      # read-only session and hands off plans to the full-tool executor.
      dualModelConfig = ''
        ${baseConfig}

        [agent]
        planner_model  = "deepseek/deepseek-v4-pro"
        subagent_model = "deepseek/deepseek-v4-pro"
      '';

      # --- Wrappers ---

      # Default `reasonix` (single-model mode, uses global ~/.reasonix/config.toml)
      reasonixDefault = pkgs.writeShellScriptBin "reasonix" ''
        if [ -r "${deepseek-api-key.path}" ]; then
          export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';

      # Single-model wrappers pinned to a specific model via --model
      mkSingleWrapper =
        name: model:
        pkgs.writeShellScriptBin "reasonix-${name}" ''
          if [ -r "${deepseek-api-key.path}" ]; then
            export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.reasonix} --model "${model}" "$@"
        '';

      singleWrappers = [
        (mkSingleWrapper "pro" "deepseek/deepseek-v4-pro")
        (mkSingleWrapper "flash" "deepseek/deepseek-v4-flash")
      ];

      # Two-model wrapper: copies the store config to a writable temp dir at
      # runtime so reasonix can write migrations/upgrades without hitting the
      # read-only Nix store. REASONIX_HOME points reasonix at this temp config,
      # enabling planner_model for the coordinator.
      dualConfigToml = pkgs.writeText "reasonix-dual-config.toml" dualModelConfig;

      reasonixDual = pkgs.writeShellScriptBin "reasonix-dual" ''
        if [ -r "${deepseek-api-key.path}" ]; then
          export DEEPSEEK_API_KEY="[redacted] "${deepseek-api-key.path}")"
        fi
        REASONIX_HOME=$(mktemp -d "''${TMPDIR:-/tmp}/reasonix-dual.XXXXXXXX")
        cp ${dualConfigToml} "$REASONIX_HOME/config.toml"
        export REASONIX_HOME
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';

    in
    {
      home.packages = [
        pkgs.llm-agents.codegraph
        reasonixDefault
      ]
      ++ singleWrappers
      ++ [
        reasonixDual
      ];

      # reasonix may rewrite this file at runtime (e.g. updating settings),
      # so force overwrite to avoid backup-file collisions on re-activation.
      xdg.configFile."reasonix/config.toml".force = true;
      xdg.configFile."reasonix/config.toml".text = singleModelConfig;

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
      };
    };
}
