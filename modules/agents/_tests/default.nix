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
    builtins.all (provider: builtins.all predicate (lib.attrValues provider.models)) (
      lib.attrValues registry
    );

  # Exercise the actual client modules, without building packages or reading keys.
  clientArgs = {
    inherit lib config;
    pkgs.coreutils = "/test/coreutils";
  };
  piModule = (import ../pi.nix).flake.modules.home."agents/pi" clientArgs;
  ompModule = (import ../omp.nix).flake.modules.home."agents/omp" clientArgs;
  dshModule = (import ../dsh.nix).flake.modules.home."agents/dsh" clientArgs;
  pi = builtins.fromJSON piModule.home.file."./.pi/agent/models.json".text;
  omp = builtins.fromJSON ompModule.home.file."./.omp/agent/models.yml".text;
  dsh = builtins.fromJSON dshModule.home.file.".dsh/cordis.patch.yml".text;
  dshEntry = id: lib.findFirst (entry: entry.id == id) (throw "missing DSH entry ${id}") dsh;
  sol = models: lib.findFirst (model: model.id == "gpt-6.1-sol") (throw "missing Sol") models;
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
    expected = catalog."openai/gpt-6.1-sol" // {
      id = "gpt-6.1-sol";
    };
  };
  testAgentDefaultOverride = {
    expr =
      (context {
        openai = {
          enable = true;
          default = true;
          defaultModel = "gpt_6_luna";
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
      id = "gpt-6.1-sol";
      name = catalog."openai/gpt-6.1-sol".name;
      reasoning = true;
      contextWindow = 1050000;
      maxTokens = 128000;
      input = [
        "text"
        "image"
      ];
    };
  };
  testOmpNativeModelSchema = {
    expr = sol omp.providers.openai.models;
    expected = sol pi.providers.openai.models;
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
    expected = builtins.removeAttrs (sol pi.providers.openai.models) [ "reasoning" ];
  };
  testDshProviderConnection = {
    expr = builtins.removeAttrs (dshEntry "llm-pi-ai").config.providers.qwen [ "models" ];
    expected = {
      displayName = "Qwen Token Plan";
      apiKeyEnv = "QWEN_API_KEY";
      baseURL = registry.qwen.endpoints.openai;
      api = "openai-completions";
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
    expr = everyModel (
      model:
      builtins.attrNames model == [
        "id"
        "model"
      ]
    );
    expected = true;
  };
  testAllModelReferencesExist = {
    expr = everyModel (model: builtins.hasAttr model.model catalog);
    expected = true;
  };
  testCatalogContainsOnlyModelFacts = {
    expr = builtins.all (
      model:
      builtins.removeAttrs model [
        "name"
        "description"
        "reasoning"
        "tool_call"
        "modalities"
        "limit"
      ] == { }
    ) (lib.attrValues catalog);
    expected = true;
  };
  testCatalogHasUsableCapabilities = {
    expr = builtins.all (
      model:
      builtins.isString model.name
      && builtins.isBool model.reasoning
      && builtins.isBool model.tool_call
      && model.limit.context > 0
      && builtins.elem "text" model.modalities.input
      && (!(model.limit ? output) || model.limit.output > 0)
    ) (lib.attrValues catalog);
    expected = true;
  };
  testSnapshotOnlyContainsReferencedModels = {
    expr = builtins.attrNames (builtins.fromJSON (builtins.readFile ../_models/models-dev.json));
    expected = lib.sort builtins.lessThan (
      lib.unique (
        lib.concatMap (
          provider:
          map (model: model.model) (
            lib.filter (model: !(lib.hasPrefix "local/" model.model)) (lib.attrValues provider.models)
          )
        ) (lib.attrValues registry)
      )
    );
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
}
