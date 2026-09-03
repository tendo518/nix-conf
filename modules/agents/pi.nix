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

      toPiProvider =
        _name: provider:
        let
          agentConfig = provider.agents.pi;
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
        in
        {
          inherit (provider) name;
          baseUrl = provider.endpoints.${agentConfig.endpoint};
          api = agentConfig.api;
          apiKey = if provider ? secret then apiKeyCommand provider.secret.path else provider.apiKey;
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

      defaultEntry = lib.findFirst (entry: entry.provider.agents.pi ? defaultModel) null (
        lib.mapAttrsToList (name: provider: { inherit name provider; }) selected
      );

      defaultProvider = if defaultEntry == null then null else defaultEntry.name;
      defaultModel =
        if defaultEntry == null then
          null
        else
          defaultEntry.provider.models.${defaultEntry.provider.agents.pi.defaultModel}.id;

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

      home.file."./.pi/agent/models.json".force = true;
      home.file."./.pi/agent/models.json".text = modelsJson;
      home.file."./.pi/agent/settings.json".force = true;
      home.file."./.pi/agent/settings.json".text = settingsJson;

      age.secrets = providers.ageSecrets selected;
    };
}
