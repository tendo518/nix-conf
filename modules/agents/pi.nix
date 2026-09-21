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
      apiKeyCommand = path: "!${pkgs.coreutils}/bin/cat ${path}";

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

      defaultProvider = "senseaudio";
      defaultModel =
        (selected.${defaultProvider}.models.${selected.${defaultProvider}.agents.pi.defaultModel}).id;

      toPiProvider =
        _name: provider:
        let
          agentConfig = provider.agents.pi;
        in
        {
          inherit (provider) name;
          baseUrl = provider.endpoints.${agentConfig.endpoint};
          api = providers.endpointApis.${agentConfig.endpoint};
          apiKey = apiKeyCommand (config.age.secrets.${provider.secret}.path);
          models = lib.mapAttrsToList (
            _model: model:
            ({
              id = model.id;
              name = model.displayName;
              inherit (model) contextWindow;
              input = model.input or [ "text" ];
            })
            // (lib.optionalAttrs (model ? thinking) {
              reasoning = true;
              thinkingLevelMap = thinkingLevelMap model.thinking.efforts;
            })
          ) provider.models;
        };

      piProviders = lib.mapAttrs toPiProvider selected;

      modelsJson = builtins.toJSON {
        providers = piProviders;
      };

      settingsJson = builtins.toJSON {
        inherit defaultProvider defaultModel;
        quietStartup = true;
      };
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
