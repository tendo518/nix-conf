# Agent modules

Home-manager modules for the installed coding agents. Provider endpoints,
credentials, model capabilities, and agent-specific defaults live in one
registry: [`_providers.nix`](./_providers.nix). Each agent module only turns
that registry into its tool's native configuration.

| Path | Purpose |
| --- | --- |
| `_providers.nix` | Private provider/model registry shared by all agent modules. |
| `claude-code.nix` | Claude Code wrappers and settings. |
| `codex/default.nix` | Codex base config, provider profiles, wrappers, and generated catalogs. |
| `codex/_model-baseline.json` | Provider-neutral Codex catalog fields, plus the shared runtime instructions. |
| `omp.nix` | OpenCode model and runtime configuration. |
| `pi.nix` | Pi model and runtime configuration. |
| `reasonix.nix` | Reasonix configuration for the DeepSeek provider. |
| `base.nix`, `ccstatusline.nix` | Shared agent packages and Claude Code status line. |

Files prefixed with `_` are private helpers/data; `import-tree` does not expose
them as selectable modules. The Codex module stays selectable as `agents/codex`
because it is registered by `codex/default.nix`.

## Provider registry

```nix
provider = {
  name = "Provider name";
  secret = "agenix-secret-name";   # resolves to secrets/<name>.age

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

  agents.omp = {
    enable = true;
    endpoint = "anthropic";        # picks endpoints.anthropic and its wire api
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

`secret` is an agenix secret name: `file` and `path` are derived from it, so a
secret is declared once in `secrets/` and `secrets/secrets.nix`. Only define the
endpoints an enabled agent reads. A provider whose `agents.<agent>.enable` is
false stays in the registry but is wired into nothing: it loses its wrappers,
its generated config, and its agenix secret.

Model fields are capability declarations, not inferred defaults:

| Field | Meaning |
| --- | --- |
| `id` | Provider model identifier. |
| `anthropicId` | Optional identifier for an Anthropic-compatible endpoint. |
| `displayName`, `description` | UI metadata; `description` is optional. |
| `contextWindow`, `maxOutputTokens` | Optional token limits. |
| `input` | Accepted modalities, normally `[ "text" ]` or `[ "text" "image" ]`. |
| `codexCatalog.<field>` | Raw Codex catalog attributes, merged verbatim over the derived entries: `priority`, `supports_image_detail_original`, `supports_search_tool`, and anything else the catalog accepts. |
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

For Codex, the generic catalog fields come from `codex/_model-baseline.json`,
which `codex/default.nix` overlays with entries derived from the registry `id`,
`displayName`, `description`, `contextWindow`, `input`, and `thinking` fields,
and finally with the model's `codexCatalog` attributes exactly as written. That
last layer is a plain merge, so declaring a catalog field never needs new code
in the agent module: overriding a derived entry and adding a field the registry
has no concept of both work the same way. The
baseline also carries the shared Codex runtime instructions
(`base_instructions` and `model_messages.instructions_template`), because the
Codex CLI requires every catalog model to define at least one of them. They are
identical across providers — they set the Codex agent's behavior, not a
provider's capabilities — so they belong in the baseline instead of being
repeated per model. Do not add provider-specific instruction overrides.

## Adding or changing a model

1. Add or update the model in `_providers.nix`, including its documented input
   modalities and exact reasoning efforts.
2. Set `agents.<agent>.enable` and the endpoint fields for every tool that
   should expose the provider.
3. Add an agenix secret under `secrets/` and register it in `secrets/secrets.nix`.
4. Run `just fmt` and `just check`.

New Nix files must be staged with `git add` before flake evaluation. The files
in this directory deliberately share the registry; do not duplicate provider
URLs, credential paths, model IDs, or capability lists in an agent module.
