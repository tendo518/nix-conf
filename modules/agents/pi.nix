{
  flake.modules.home."agents/pi" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_providers.nix { inherit config lib; };
      selected = providers.selectProviders "pi";

      thinkingLevelMap =
        efforts:
        let
          levels = [
            "minimal"
            "low"
            "medium"
            "high"
            "xhigh"
            "max"
          ];
        in
        lib.genAttrs levels (level: if builtins.elem level efforts then level else null);

      defaultProvider = providers.defaultProvider selected;
      defaultProviderConfig = selected.${defaultProvider};
      defaultModel =
        defaultProviderConfig.models.${
          defaultProviderConfig.agentConfig.defaultModel or defaultProviderConfig.defaultModel
        };

      toPiProvider = _name: provider: {
        inherit (provider) name;
        baseUrl = provider.endpoints.openai;
        api = provider.agentConfig.api or "openai-completions";
        apiKey = ''!${pkgs.coreutils}/bin/cat "${provider.secretPath}"'';
        models = lib.mapAttrsToList (
          _model: model:
          {
            id = model.id;
            name = model.displayName;
            inherit (model) contextWindow;
            input = model.input or [ "text" ];
          }
          // lib.optionalAttrs (model ? maxOutputTokens) {
            maxTokens = model.maxOutputTokens;
          }
          // lib.optionalAttrs (model ? thinking) {
            reasoning = true;
            thinkingLevelMap = thinkingLevelMap model.thinking.efforts;
          }
        ) provider.models;
      };

      piProviders = lib.mapAttrs toPiProvider selected;

      modelsJson = builtins.toJSON {
        providers = piProviders;
      };

      # Intentionally unpinned: Pi resolves these when installing or updating,
      # and the selected versions are recorded in ~/.pi/agent/npm.
      piPackages = [
        "npm:@companion-ai/feynman"
        "npm:@narumitw/pi-statusline"
        "npm:@narumitw/pi-tool"
        "npm:@narumitw/pi-usage"
        "npm:@tintinweb/pi-subagents"
        "npm:pi-open-tui"
        "npm:pi-web-access"
      ];

      settingsJson = builtins.toJSON (
        {
          inherit defaultProvider;
          defaultModel = defaultModel.id;
          packages = piPackages;
          quietStartup = true;
        }
        // lib.optionalAttrs (defaultModel ? thinking) {
          defaultThinkingLevel = defaultModel.thinking.default;
        }
      );

      piSettingsDefaults = pkgs.writeText "pi-settings.json" settingsJson;
    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      home.file."./.pi/agent/models.json" = {
        force = true;
        text = modelsJson;
      };

      # Keep Pi's settings writable so `pi install`, `pi remove`, and
      # `pi config` can persist changes. Nix defaults are merged on activation,
      # while packages installed at runtime are retained.
      home.activation.setupPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        piSettings="$HOME/.pi/agent/settings.json"
        mkdir -p "$(dirname "$piSettings")"

        # Migrate the read-only home-manager symlink from earlier generations.
        if [ -L "$piSettings" ]; then
          rm -f "$piSettings"
        fi

        if [ -f "$piSettings" ]; then
          tmp="$(mktemp "$piSettings.tmp.XXXXXX")"
          ${lib.getExe pkgs.jq} -s '
            .[0] as $current
            | .[1] as $defaults
            | ($current + $defaults)
            | .packages = ((($current.packages // []) + ($defaults.packages // [])) | unique)
          ' "$piSettings" ${piSettingsDefaults} > "$tmp"
          chmod 600 "$tmp"
          mv "$tmp" "$piSettings"
        else
          install -m 600 ${piSettingsDefaults} "$piSettings"
        fi
      '';

      age.secrets = providers.ageSecrets selected;
    };
}
