{
  flake.modules.home."agents/reasonix" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_providers.nix { inherit config lib; };
      selected = providers.selectProviders "reasonix";
      defaultProvider = providers.defaultProvider selected;
      provider = selected.${defaultProvider};
      agentConfig = provider.agentConfig;
      defaultModel = provider.models.${agentConfig.defaultModel or provider.defaultModel};
      apiKeyEnv = "${lib.toUpper defaultProvider}_API_KEY";
      reasonixHome = "${config.xdg.configHome}/reasonix";
      secretPath = provider.secretPath;

      # agenix mounts secrets in a separate user service. Sync both during
      # activation and at launch, when the latest secret is available.
      syncReasonixEnv = ''
        # agenix exposes home secrets under $XDG_RUNTIME_DIR, which the
        # system-level home-manager service does not export while it runs
        # activation. It always runs as the owning user, so default to that
        # user's runtime dir (same idiom home-manager uses for reloadSystemd).
        : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
        if [ -r "${secretPath}" ]; then
          (
            set -e
            umask 077
            mkdir -p "${reasonixHome}"
            envFile="${reasonixHome}/.env"
            tmp="$(mktemp "$envFile.XXXXXX")"
            trap 'rm -f "$tmp"' EXIT
            if [ -f "$envFile" ]; then
              ${pkgs.gnused}/bin/sed -E \
                -e '/^[[:space:]]*(export[[:space:]]+)?${apiKeyEnv}[[:space:]]*=/d' \
                -e '/^# reasonix-cleared ${apiKeyEnv}$/d' \
                "$envFile" > "$tmp"
            fi
            key="$(cat "${secretPath}")"
            printf '${apiKeyEnv}=%s\n' "$key" >> "$tmp"
            mv "$tmp" "$envFile"
          )
        fi
      '';

      reasonixWrapped = pkgs.writeShellScriptBin "reasonix" ''
        set -e
        export REASONIX_HOME="${reasonixHome}"
        ${syncReasonixEnv}
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';

      reasonixConfig = (pkgs.formats.toml { }).generate "reasonix-config.toml" {
        config_version = 5;
        default_model = defaultProvider;
        language = "zh";
        ui = {
          theme = "auto";
          show_reasoning = true;
        };
        notifications = {
          enabled = true;
          turn_done = true;
          approval_request = true;
          ask_request = true;
        };
        telemetry.cli_metrics = "off";
        desktop = {
          telemetry = false;
          metrics = false;
        };
        agent = {
          temperature = 0.0;
          auto_plan = "off";
          soft_compact_ratio = 0.5;
          compact_ratio = 0.8;
          compact_force_ratio = 0.9;
        };
        providers = [
          (
            {
              name = defaultProvider;
              kind = "openai";
              base_url = provider.endpoints.openai;
              models = map (model: model.id) (lib.attrValues provider.models);
              default = defaultModel.id;
              api_key_env = apiKeyEnv;
              effort = defaultModel.thinking.default;
              context_window = defaultModel.contextWindow;
            }
            // lib.optionalAttrs (provider.endpoints ? balance) {
              balance_url = provider.endpoints.balance;
            }
            // lib.optionalAttrs (defaultModel ? maxOutputTokens) {
              max_output_tokens = defaultModel.maxOutputTokens;
            }
          )
        ];
        tools = {
          enabled = [ ];
          bash_timeout_seconds = 120;
        };
        serve = {
          auth_mode = "none";
          behind_proxy = false;
        };
        permissions.mode = "ask";
        sandbox = {
          workspace_root = "";
          allow_write = [ "/tmp" ];
          bash = "enforce";
          network = true;
        };
      };
    in
    {
      home.packages = [
        pkgs.llm-agents.codegraph
        reasonixWrapped
      ];

      xdg.configFile."reasonix/config.toml".force = true;
      xdg.configFile."reasonix/config.toml".source = reasonixConfig;

      home.activation.setupReasonixEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] syncReasonixEnv;

      age.secrets = providers.ageSecrets selected;
    };
}
