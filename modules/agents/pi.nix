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
        api = "openai-completions";
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

      settingsJson = builtins.toJSON (
        {
          inherit defaultProvider;
          defaultModel = defaultModel.id;
          quietStartup = true;
        }
        // lib.optionalAttrs (defaultModel ? thinking) {
          defaultThinkingLevel = defaultModel.thinking.default;
        }
      );
    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      home.file."./.pi/agent/models.json" = {
        force = true;
        text = modelsJson;
      };
      home.file."./.pi/agent/settings.json" = {
        force = true;
        text = settingsJson;
      };

      age.secrets = providers.ageSecrets selected;
    };
}
