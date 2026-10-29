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
        "npm:@ff-labs/pi-fff"
        "npm:@narumitw/pi-btw"
        "npm:@narumitw/pi-goal"
        "npm:@narumitw/pi-plan-mode"
        "npm:@narumitw/pi-statusline"
        "npm:@narumitw/pi-tool"
        "npm:@narumitw/pi-usage"
        "npm:pi-open-tui"
        "npm:pi-subagents"
        "npm:pi-web-access"
      ];

      settingsJson = builtins.toJSON (
        {
          "$schema" = "https://pi.dev/schemas/settings.schema.json";
          inherit defaultProvider;
          defaultModel = defaultModel.id;
          packages = piPackages;
          quietStartup = true;
          enableInstallTelemetry = false;
          retry.provider.maxRetries = 0;
          theme = "dark";
          hideThinkingBlock = true;
          tuiMode = "fullscreen";
          fullscreenWheelScrollLines = "auto";
          terminal.showTerminalProgress = true;
        }
        // lib.optionalAttrs (defaultModel ? thinking) {
          defaultThinkingLevel = defaultModel.thinking.default;
        }
      );

      piSettingsDefaults = pkgs.writeText "pi-settings.json" settingsJson;

      # pi-open-tui keeps its own config outside settings.json.
      openTuiConfig = {
        enabled = true;
        inlineFooter = true;
        settingsLanguage = "en";
        cursorStyle = "block";
        icons.mode = "ascii";
        footerSegments = {
          cwd = true;
          hostname = true;
          sessionName = true;
          gitBranch = true;
          gitStatus = true;
          gitCommit = false;
          runtime = true;
          context = true;
          tokens = true;
          cost = true;
          extensionStatuses = true;
          capitalizeProviderName = true;
          nerdIconSpacing = false;
        };
        telemetry = {
          enabled = true;
          tps = true;
          ttft = true;
          duration = true;
          tokens = true;
          stalls = true;
          cost = true;
        };
        thinkingPeek.lines = 2;
      };

      openTuiDefaults = pkgs.writeText "pi-open-tui.json" (builtins.toJSON openTuiConfig);
    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      home.file."./.pi/agent/models.json" = {
        force = true;
        text = modelsJson;
      };

      # Rewrite Pi's settings from the Nix defaults on every activation. The
      # files stay writable so `pi install`, `pi config`, and extension UIs work
      # at runtime, but their changes are discarded on the next switch.
      home.activation.setupPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        piSettings="$HOME/.pi/agent/settings.json"
        openTui="$HOME/.pi/agent/open-tui.json"
        mkdir -p "$(dirname "$piSettings")"

        # Drop any previous file, including the read-only home-manager symlink
        # from earlier generations.
        rm -f "$piSettings"
        install -m 600 ${piSettingsDefaults} "$piSettings"

        rm -f "$openTui"
        install -m 644 ${openTuiDefaults} "$openTui"
      '';

      age.secrets = providers.ageSecrets selected;
    };
}
