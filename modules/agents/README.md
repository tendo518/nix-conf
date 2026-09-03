# Agent modules

This directory declares the home-manager modules for the installed coding
agents. Provider endpoints, credentials, model capabilities, and agent-specific
defaults live in one registry: [`_providers.nix`](./_providers.nix). Individual
agent modules only turn that registry into each tool's native configuration.

## Layout

| Path | Purpose |
| --- | --- |
| `_providers.nix` | Private provider/model registry shared by all agent modules. |
| `claude-code.nix` | Claude Code wrappers and settings. |
| `codex/default.nix` | Codex base config, provider profiles, wrappers, and generated model catalogs. |
| `codex/_model-baseline.json` | Provider-neutral Codex catalog fields, based on DeepSeek's official catalog. |
| `omp.nix` | OpenCode model and runtime configuration. |
| `pi.nix` | Pi model and runtime configuration. |
| `reasonix.nix` | Reasonix configuration for the DeepSeek provider. |
| `base.nix`, `ccstatusline.nix` | Shared agent packages and Claude Code status line. |

Files prefixed with `_` are private helpers/data; `import-tree` does not expose
them as selectable modules. The Codex module remains selectable as
`agents/codex` because it is registered by `codex/default.nix`.

## Provider registry

Each provider in `_providers.nix` has this shape:

```nix
provider = {
  name = "Provider name";
  secret = {
    name = "agenix-secret-name";
    file = ../../secrets/agenix-secret-name.age;
    path = config.age.secrets.agenix-secret-name.path;
  };
  # Or, for a non-agenix provider: apiKey = "...";

  endpoints = {
    responses = "https://...";
    anthropic = "https://...";
    openai = "https://...";
  };

  agents.codex = {
    enable = true;
    profile = "codex-provider";
    providerName = "provider-id";
    defaultModel = "model_key";
  };

  models.model_key = {
    id = "upstream-model-id";
    displayName = "Model name";
    contextWindow = 1000000;
    input = [ "text" "image" ];
    supportsImageDetailOriginal = true;
    thinking = {
      efforts = [ "low" "high" ];
      default = "high";
    };
  };
};
```

Only define the endpoints required by enabled agents. `secret` providers are
registered as agenix secrets by each consuming module; `apiKey` is for the
local GPU-style provider that does not use agenix.

Model fields are capability declarations, not inferred defaults:

| Field | Meaning |
| --- | --- |
| `id` | Provider model identifier. |
| `anthropicId` | Optional identifier for an Anthropic-compatible endpoint. |
| `displayName`, `description`, `priority` | UI metadata; the latter two are optional. |
| `contextWindow`, `maxOutputTokens` | Optional token limits. |
| `input` | Accepted modalities, normally `[ "text" ]` or `[ "text" "image" ]`. |
| `supportsImageDetailOriginal` | Whether the model supports Codex's `original` image-detail mode. It is independent of ordinary image input. |
| `thinking.efforts`, `thinking.default` | Exact provider-supported effort levels and the provider's default. |

Define effort levels and image capabilities only in this registry. Consumers
must preserve those declarations rather than adding model-specific validation
or guessed capabilities.

## Agent outputs

| Module | Generated command/configuration |
| --- | --- |
| Claude Code | One `cc-<provider>-<model>` wrapper per enabled provider model. The provider's optional `effortLevel` is exported as `CLAUDE_CODE_EFFORT_LEVEL`. |
| Codex | `codex` plus one `codex-<provider>` wrapper per enabled provider. Profiles and generated catalogs are installed below `$XDG_CONFIG_HOME/codex`; `~/.codex` is linked there. |
| OMP | `~/.omp/agent/models.yml` and `config.yml`; model thinking entries carry the declared efforts and default level. |
| Pi | `~/.pi/agent/models.json` and `settings.json`; supported Pi levels are mapped from each model's declared effort list. |
| Reasonix | `$XDG_CONFIG_HOME/reasonix/config.toml` and its protected `.env`; currently this module intentionally targets the enabled DeepSeek provider. |

For Codex, the generic catalog fields are loaded from
`codex/_model-baseline.json`. `codex/default.nix` overlays model-specific IDs,
limits, modalities, image-detail capability, reasoning levels, descriptions,
and priorities. Do not copy provider catalog `base_instructions` or
`model_messages` into the baseline: they are Codex runtime instructions rather
than provider capability metadata.

## Adding or changing a model

1. Add or update the model in `_providers.nix`, including its documented input
   modalities and exact reasoning efforts.
2. Set the corresponding `agents.<agent>.enable` and required endpoint fields
   for every tool that should expose the provider.
3. Add an agenix secret under `secrets/` and register it in `secrets/secrets.nix`
   when using `secret` authentication.
4. Run `just fmt` and `just check`.

New Nix files must be staged with `git add` before flake evaluation. The files
in this directory deliberately share the registry; do not duplicate provider
URLs, credential paths, model IDs, or capability lists in an individual agent
module.
