{
  flake.modules.home."agents/omp" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_providers.nix { inherit config lib; };
      selected = providers.selectProviders "omp";
      apiKeyCommand = path: "!${pkgs.coreutils}/bin/cat ${path}";

      toOmpProvider =
        _name: provider:
        let
          agentConfig = provider.agents.omp;
          thinking = model: model.thinking or null;
        in
        {
          baseUrl = provider.endpoints.${agentConfig.endpoint};
          api = agentConfig.api;
          apiKey = if provider ? secret then apiKeyCommand provider.secret.path else provider.apiKey;
          models = lib.mapAttrsToList (
            _model: model:
            (
              {
                id = model.anthropicId or model.id;
                name = model.displayName;
                inherit (model) contextWindow;
                input = model.input or [ "text" ];
              }
              // (lib.optionalAttrs (model ? maxOutputTokens) {
                maxTokens = model.maxOutputTokens;
              })
            )
            // (lib.optionalAttrs (thinking model != null) {
              reasoning = true;
              thinking = {
                mode = "effort";
                efforts = (thinking model).efforts;
                defaultLevel = (thinking model).default;
              };
            })
          ) provider.models;
        };

      ompProviders = lib.mapAttrs toOmpProvider selected;

      defaultEntry = lib.findFirst (entry: entry.provider.agents.omp ? defaultModel) null (
        lib.mapAttrsToList (name: provider: { inherit name provider; }) selected
      );

      defaultProvider = if defaultEntry == null then null else defaultEntry.name;
      defaultModel =
        if defaultEntry == null then
          null
        else
          defaultEntry.provider.models.${defaultEntry.provider.agents.omp.defaultModel}.id;

      modelsYml = builtins.toJSON {
        providers = ompProviders;
      };

      configYml = builtins.toJSON {
        setupVersion = 1;
        modelRoles.default = "${defaultProvider}/${defaultModel}";
        startup = {
          checkUpdate = false;
          setupWizard = false;
          quiet = true;
        };
        marketplace.autoUpdate = "off";
        model.loopGuard.enabled = true;
        retry.maxRetries = 5;
        task = {
          enableLsp = true;
          maxConcurrency = 8;
        };
        display.showTokenUsage = true;
        symbolPreset = "ascii";
        statusLine.preset = "default";
        images.blockImages = true;
        secrets.enabled = true;
      };
    in
    {
      home.packages = [ pkgs.llm-agents.omp ];

      home.file."./.omp/agent/models.yml".force = true;
      home.file."./.omp/agent/models.yml".text = modelsYml;
      home.file."./.omp/agent/config.yml".force = true;
      home.file."./.omp/agent/config.yml".text = configYml;

      age.secrets = providers.ageSecrets selected;
    };
}
