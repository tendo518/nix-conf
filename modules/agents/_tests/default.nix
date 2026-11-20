{ lib }:
let
  registry = import ../_providers.nix;
  catalog = import ../_models;
  config.age.secrets = lib.listToAttrs (
    map (provider: lib.nameValuePair provider.secret { path = "/run/secrets/${provider.secret}"; }) (
      lib.attrValues registry
    )
  );
  context = settings: import ../_context.nix { inherit lib config settings; };
  configured = lib.mapAttrs (_: context) (import ../_agents.nix);
  selected = context {
    openai = {
      enable = true;
      default = true;
    };
  };
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  everyModel =
    predicate:
    builtins.all (provider: builtins.all predicate provider.models) (lib.attrValues registry);

  # Exercise the actual client modules, without building packages or reading keys.
  clientArgs = {
    inherit lib config;
    pkgs.coreutils = "/test/coreutils";
  };
  piModule = (import ../pi.nix).flake.modules.home."agents/pi" clientArgs;
  ompModule = (import ../omp.nix).flake.modules.home."agents/omp" clientArgs;
  dshModule = (import ../dsh.nix).flake.modules.home."agents/dsh" clientArgs;
  reasonixModule = (import ../reasonix.nix).flake.modules.home."agents/reasonix" (
    clientArgs
    // {
      pkgs = clientArgs.pkgs // {
        gnused = "/test/gnused";
        formats.toml = { }: { generate = _: builtins.toJSON; };
        writeShellScriptBin = name: _: name;
        llm-agents.reasonix = "/test/reasonix";
        codegraph = "/test/codegraph";
      };
      config = clientArgs.config // {
        home.homeDirectory = "/test/home";
        xdg.configHome = "/test/config";
      };
    }
  );
  pi = builtins.fromJSON piModule.home.file."./.pi/agent/models.json".text;
  omp = builtins.fromJSON ompModule.home.file."./.omp/agent/models.yml".text;
  dsh = builtins.fromJSON dshModule.home.file.".dsh/cordis.patch.yml".text;
  dshEntry = id: lib.findFirst (entry: entry.id == id) (throw "missing DSH entry ${id}") dsh;
  sol = models: lib.findFirst (model: model.id == "gpt-6.2-sol") (throw "missing Sol") models;
  luna = models: lib.findFirst (model: model.id == "gpt-6-luna") (throw "missing Luna") models;
  qwenMax = models: lib.findFirst (model: model.id == "qwen3.8-max") (throw "missing Qwen Max") models;
in
lib.runTests {
  testOmittedProvidersAreDisabled = {
    expr = builtins.attrNames selected.selected;
    expected = [ "openai" ];
  };
  testDisabledProvidersAreLazy = {
    expr =
      builtins.attrNames
        (context {
          openai = {
            enable = false;
            defaultModel = "missing";
          };
        }).selected;
    expected = [ ];
  };
  testUnknownProviderRejected = {
    expr = fails (context { typo.enable = false; }).selected;
    expected = true;
  };
  testMissingEnableRejected = {
    expr = fails (context { openai = { }; }).selected;
    expected = true;
  };
  testInvalidEnableRejected = {
    expr = fails (context { openai.enable = "yes"; }).selected;
    expected = true;
  };
  testDefaultProvider = {
    expr = selected.defaultProvider;
    expected = "openai";
  };
  testNoGlobalDefaultNeededForSelection = {
    expr = builtins.attrNames (context { openai.enable = true; }).selected;
    expected = [ "openai" ];
  };
  testMissingDefaultRejected = {
    expr = fails (context { openai.enable = true; }).defaultProvider;
    expected = true;
  };
  testMultipleDefaultsRejected = {
    expr =
      fails
        (context {
          openai = {
            enable = true;
            default = true;
          };
          deepseek = {
            enable = true;
            default = true;
          };
        }).defaultProvider;
    expected = true;
  };
  testDefaultResolvesModelFactsAndApiId = {
    expr = selected.defaultModel;
    expected = catalog.openai."gpt-6.2-sol" // {
      id = "gpt-6.2-sol";
    };
  };
  testAgentDefaultOverride = {
    expr =
      (context {
        openai = {
          enable = true;
          default = true;
          defaultModel = "gpt-6-luna";
        };
      }).defaultModel.id;
    expected = "gpt-6-luna";
  };
  testUnknownDefaultRejected = {
    expr =
      fails
        (context {
          openai = {
            enable = true;
            defaultModel = "missing";
          };
        }).selected.openai.defaultModel;
    expected = true;
  };
  testAliasKeepsServingId = {
    expr = (context { deepseek.enable = true; }).selected.deepseek.defaultModel.id;
    expected = "deepseek-flash";
  };
  testLocalModelResolves = {
    expr = fails ((context { gpu.enable = true; }).selected.gpu.models."qwen3.8-27b");
    expected = false;
  };
  testModelIdsAreUnique = {
    expr = builtins.all (
      provider:
      let
        ids = map (id: if lib.hasPrefix "local/" id then catalog.local.${id}.id else id) provider.models;
      in
      lib.unique ids == ids
    ) (lib.attrValues registry);
    expected = true;
  };
  testOnlyEnabledSecretsAreDeclared = {
    expr = builtins.attrNames selected.ageSecrets;
    expected = [ "openai-api-key" ];
  };
  testSecretIsReadAtRuntime = {
    expr = pi.providers.openai.apiKey;
    expected = ''!/test/coreutils/bin/cat "/run/secrets/openai-api-key"'';
  };
  testPiNativeModelSchema = {
    expr = sol pi.providers.openai.models;
    expected = {
      id = "gpt-6.2-sol";
      name = catalog.openai."gpt-6.2-sol".name;
      reasoning = true;
      contextWindow = catalog.openai."gpt-6.2-sol".limit.context;
      maxTokens = catalog.openai."gpt-6.2-sol".limit.output;
      input = [
        "text"
        "image"
      ];
      thinkingLevelMap = {
        off = null;
        minimal = null;
        low = "low";
        medium = "medium";
        high = "high";
        xhigh = "xhigh";
        max = "max";
      };
    };
  };
  testOmpNativeModelSchema = {
    expr = sol omp.providers.openai.models;
    expected = builtins.removeAttrs (sol pi.providers.openai.models) [ "thinkingLevelMap" ] // {
      thinking = {
        mode = "effort";
        efforts = [
          "low"
          "medium"
          "high"
          "xhigh"
          "max"
        ];
        effortMap = {
          low = "low";
          medium = "medium";
          high = "high";
          xhigh = "xhigh";
          max = "max";
        };
      };
    };
  };
  testPiQwenUsesResponsesWithSupportedLevels = {
    expr = {
      api = pi.providers.qwen.api;
      compat = pi.providers.qwen.compat or { };
      thinkingLevelMap = (qwenMax pi.providers.qwen.models).thinkingLevelMap;
    };
    expected = {
      api = "openai-responses";
      compat = { };
      thinkingLevelMap = {
        off = null;
        minimal = null;
        low = "low";
        medium = "medium";
        high = null;
        xhigh = "xhigh";
        max = null;
      };
    };
  };
  testPiDeepSeekUsesNativeThinkingFormat = {
    expr = pi.providers.deepseek.compat;
    expected = {
      supportsReasoningEffort = true;
      thinkingFormat = "deepseek";
    };
  };
  testOmpQwenSendsEffortWithThinkingToggle = {
    expr = omp.providers.qwen.compat;
    expected = {
      supportsReasoningEffort = true;
      thinkingFormat = "qwen";
      qwenTemplateReasoningEffort = true;
    };
  };
  testGpuHasExplicitEffortLevels = {
    expr = (lib.head pi.providers.gpu.models).thinkingLevelMap;
    expected = {
      off = "none";
      minimal = null;
      low = "low";
      medium = "medium";
      high = null;
      xhigh = "xhigh";
      max = null;
    };
  };
  testPiMapsNonThinkingToNone = {
    expr = (luna pi.providers.openai.models).thinkingLevelMap.off;
    expected = "none";
  };
  testOmpKeepsOffOutsideEffortLadder = {
    expr = (luna omp.providers.openai.models).thinking;
    expected = {
      mode = "effort";
      efforts = [
        "low"
        "medium"
        "high"
        "xhigh"
        "max"
      ];
      effortMap.low = "low";
      effortMap.medium = "medium";
      effortMap.high = "high";
      effortMap.xhigh = "xhigh";
      effortMap.max = "max";
      requiresEffort = false;
      suppressWhenOff = true;
    };
  };
  testQwen4MaxUsesLocalFacts = {
    expr = (context { qwen.enable = true; }).selected.qwen.models."qwen4-max";
    expected = catalog.local."local/qwen4-max" // {
      id = "qwen4-max";
    };
  };
  testDshKeepsNativeDeepSeekAdapter = {
    expr = (dshEntry "llm-deepseek").config;
    expected = {
      apiKeyEnv = "DEEPSEEK_API_KEY";
      baseURL = registry.deepseek.endpoints.anthropic;
      models = map (model: {
        inherit (model) id name;
        contextWindow = model.limit.context;
        maxTokens = model.limit.output;
        inputModalities = lib.intersectLists [ "text" "image" ] model.modalities.input;
      }) (lib.attrValues configured.dsh.selected.deepseek.models);
    };
  };
  testDshPiAiProviders = {
    expr = builtins.attrNames (dshEntry "llm-pi-ai").config.providers;
    expected = [
      "openai"
      "qwen"
    ];
  };
  testDshNativeModelSchema = {
    expr = sol (dshEntry "llm-pi-ai").config.providers.openai.models;
    expected =
      builtins.removeAttrs (sol pi.providers.openai.models) [
        "reasoning"
        "thinkingLevelMap"
      ]
      // {
        reasoningEfforts = {
          low = "low";
          medium = "medium";
          high = "high";
          xhigh = "xhigh";
          max = "max";
        };
      };
  };
  testDshQwenOmitsUnsupportedLevels = {
    expr = {
      compat = (dshEntry "llm-pi-ai").config.providers.qwen.compat;
      reasoningEfforts = (qwenMax (dshEntry "llm-pi-ai").config.providers.qwen.models).reasoningEfforts;
    };
    expected = {
      compat = {
        supportsReasoningEffort = true;
        thinkingFormat = "qwen";
      };
      reasoningEfforts = {
        low = "low";
        medium = "medium";
        xhigh = "xhigh";
      };
    };
  };
  testDshProviderConnection = {
    expr = builtins.removeAttrs (dshEntry "llm-pi-ai").config.providers.qwen [ "models" ];
    expected = {
      displayName = "Qwen Token Plan";
      apiKeyEnv = "QWEN_API_KEY";
      baseURL = registry.qwen.endpoints.openai;
      api = "openai-completions";
      compat = {
        supportsReasoningEffort = true;
        thinkingFormat = "qwen";
      };
    };
  };
  testDshOpenAiUsesResponses = {
    expr = (dshEntry "llm-pi-ai").config.providers.openai.api;
    expected = "openai-responses";
  };
  testDshDoesNotPinPickerDefault = {
    expr = map (entry: entry.id) dsh;
    expected = [
      "llm-deepseek"
      "llm-pi-ai"
    ];
  };
  testDshOnlyEnabledSecretsAreDeclared = {
    expr = builtins.attrNames dshModule.age.secrets;
    expected = [
      "deepseek-api-key"
      "openai-api-key"
      "qwen-tokenplan-api-key"
    ];
  };
  testProviderModelsOnlyContainReferences = {
    expr = everyModel (model: builtins.isString model);
    expected = true;
  };
  testSubscribedModelsUseProviderFacts = {
    expr = selected.selected.openai.models."gpt-6.2-sol".reasoning_options;
    expected = catalog.openai."gpt-6.2-sol".reasoning_options;
  };
  testQwenOnlyExposesSelectedModels = {
    expr = builtins.attrNames (context { qwen.enable = true; }).selected.qwen.models;
    expected = [
      "deepseek-v4.1-flash"
      "deepseek-v4.1-flash-1017"
      "glm-5.3"
      "qwen3.8-flash"
      "qwen3.8-max"
      "qwen4-max"
    ];
  };
  testAllModelReferencesExist = {
    expr = builtins.all (
      entry:
      let
        inherit (entry) name provider;
      in
      builtins.all (
        model:
        if lib.hasPrefix "local/" model then
          builtins.hasAttr model catalog.local
        else
          builtins.hasAttr model catalog.${name}
      ) provider.models
    ) (lib.attrValues (lib.mapAttrs (name: provider: { inherit name provider; }) registry));
    expected = true;
  };
  testCatalogContainsOnlyModelFacts = {
    expr =
      builtins.all
        (
          model:
          builtins.removeAttrs model [
            "name"
            "description"
            "reasoning"
            "tool_call"
            "modalities"
            "limit"
            "reasoning_options"
          ] == { }
        )
        (
          lib.concatMap (models: lib.attrValues models) (
            lib.attrValues (builtins.removeAttrs catalog [ "local" ])
          )
          ++ map (model: builtins.removeAttrs model [ "id" ]) (lib.attrValues (import ../_models/local.nix))
        );
    expected = true;
  };
  testCatalogHasUsableCapabilities = {
    expr =
      builtins.all
        (
          model:
          builtins.isString model.name
          && builtins.isBool model.reasoning
          && builtins.isBool model.tool_call
          && model.limit.context > 0
          && builtins.elem "text" model.modalities.input
          && (!(model.limit ? output) || model.limit.output > 0)
        )
        (
          lib.concatMap (models: lib.attrValues models) (
            lib.attrValues (builtins.removeAttrs catalog [ "local" ])
          )
          ++ map (model: builtins.removeAttrs model [ "id" ]) (lib.attrValues (import ../_models/local.nix))
        );
    expected = true;
  };
  testSnapshotOnlyContainsReferencedModels = {
    expr = lib.mapAttrs (_: models: lib.sort builtins.lessThan (builtins.attrNames models)) (
      builtins.fromJSON (builtins.readFile ../_models/models-dev.json)
    );
    expected = lib.mapAttrs (
      _: provider:
      lib.sort builtins.lessThan (lib.filter (model: !(lib.hasPrefix "local/" model)) provider.models)
    ) (lib.filterAttrs (_: provider: provider ? modelsDevProvider) registry);
  };
  testAllConfiguredDefaultsResolve = {
    expr = builtins.all (
      agent:
      builtins.all (provider: provider.defaultModel == provider.models.${provider.defaultModelKey}) (
        lib.attrValues agent.selected
      )
    ) (lib.attrValues configured);
    expected = true;
  };
  testEnabledProvidersHaveRequiredEndpoints = {
    expr = lib.concatLists (
      lib.mapAttrsToList (
        agent: resolved:
        let
          endpoint =
            if
              builtins.elem agent [
                "claudeCode"
                "claudeDesktop"
              ]
            then
              "anthropic"
            else
              "openai";
        in
        map (name: "${agent}/${name}") (
          builtins.attrNames (
            lib.filterAttrs (_: provider: !(builtins.hasAttr endpoint provider.endpoints)) resolved.selected
          )
        )
      ) configured
    );
    expected = [ ];
  };
  testReasonixDeclaresEffortContract = {
    expr =
      let
        config = builtins.fromJSON reasonixModule.xdg.configFile."reasonix/config.toml".source;
        provider = lib.head config.providers;
      in
      {
        inherit (provider) effort supported_efforts reasoning_protocol;
      };
    expected = {
      effort = "high";
      supported_efforts = [
        "low"
        "high"
        "max"
      ];
      reasoning_protocol = "deepseek";
    };
  };
}
