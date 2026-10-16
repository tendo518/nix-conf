# Agent modules

Home-manager modules for the installed coding agents. Provider endpoints,
credentials, model capabilities, and defaults live in [`_providers/`](./_providers).
[`_providers.nix`](./_providers.nix) selects providers for each agent. Each agent
module translates the same model fields into its native configuration.

| Path | Purpose |
| --- | --- |
| `_providers/*.nix` | Direct provider and model declarations. |
| `_providers.nix` | Provider selection and runtime secret paths. |
| `claude-code.nix` | Claude Code wrappers and settings. |
| `codex/default.nix` | Codex base config, provider profiles, wrappers, and generated catalogs. |
| `omp.nix` | OMP model and runtime configuration. |
| `pi.nix` | Pi model and runtime configuration. |
| `reasonix.nix` | Reasonix configuration for its default provider. |
| `base.nix`, `ccstatusline.nix` | Shared agent packages and Claude Code status line. |

Files prefixed with `_` are private helpers/data; `import-tree` does not expose
them as selectable modules. The Codex module stays selectable as `agents/codex`
because it is registered by `codex/default.nix`.

## Provider registry

Each model lists its own specifications directly. Generated identifiers and
client-specific request formats belong in the agent modules.

```nix
provider = {
  name = "Provider name";
  secret = "agenix-secret-name";
  defaultModel = "model_key";
  endpoints = {
    openai = "https://example.com/v1";
    anthropic = "https://example.com/anthropic";
  };
  agents = {
    claudeCode = { };
    codex = { };
    omp = { };
    pi = { };
  };
  models.model_key = {
    id = "upstream-model-id";
    displayName = "Model name";
    contextWindow = 1000000;
    input = [ "text" "image" ];
    thinking = {
      efforts = [ "low" "high" ];
      default = "high";
    };
    claudeBehavesAs = "claude-opus-5-5";
    codexSupportsOriginalImageDetail = true;
    codexPriority = 1;
  };
};
```

`secret` names an agenix secret; the file and runtime path are derived from it.
An agent is enabled by declaring its settings, including an empty `{ }`. Omit
an agent or set its `enable = false` to disable it. Provider-level
`enable = false` disables all its integrations while retaining their settings.

Pi, OMP, Reasonix, and Claude Desktop choose their default provider through
`agents.<agent>.default = true`. Each of these agents requires exactly one
enabled default when configured; a missing or duplicate default fails evaluation.
For example, SenseAudio declares `agents.pi.default = true` and
`agents.omp.default = true`. The agent modules do not name providers directly.
Codex keeps its official OpenAI login as the default and exposes other providers
through profiles; Claude Code exposes provider/model wrapper commands.

`defaultModel` is declared once per provider. An agent may override it when it
needs a different model. Claude Code's `smallModel` also falls back to that
provider default; declare it only when a separate small model is wanted.

Codex derives its provider ID from the registry key and its profile/command as
`codex-<key>`. Only existing short aliases such as `profile = "codex-ds"` need an
explicit profile. The human-readable provider label comes from `name`. Codex's
reasoning effort comes from the chosen model's `thinking.default`.
Pi's startup thinking level also follows its selected default model's
`thinking.default`, rather than Pi's built-in default.

OMP, Pi, Reasonix, and Codex use `endpoints.openai`; Codex speaks Responses,
while the others use Chat Completions. Claude Code and Desktop use
`endpoints.anthropic`. Model IDs always remain the provider's actual IDs;
Claude Code adds `[1m]` when `contextWindow >= 950000`, treating near-million
windows as the 1M tier. Claude Desktop derives its native `supports1m` flag
using the same threshold.

| Model field | Meaning |
| --- | --- |
| `id` | Actual provider model identifier. |
| `displayName`, `description` | Shared display metadata; `description` is optional. |
| `contextWindow`, `maxOutputTokens` | Explicit token limits; output limit is optional and becomes `maxTokens` in Pi and OMP. |
| `input` | Accepted modalities; defaults to `[ "text" ]` when omitted. |
| `thinking.efforts`, `thinking.default` | Exact supported reasoning levels and default. |
| `claudeBehavesAs` | Claude model used for Code's client-side handling and Desktop's gateway route. |
| `codexPriority` | Optional picker ordering, translated into the Codex catalog. |
| `codexSupportsOriginalImageDetail` | Explicit original-image-detail support, translated into the Codex catalog. |
| `codexSupportsSearchTool` | Explicit search-tool support, translated into the Codex catalog. |

Provider-level `codexSupportsParallelToolCalls` describes a serving limitation shared
by its models. Optional capabilities are only set when explicitly declared;
image-detail support is independent of accepting image input.

Claude Desktop's provider settings list the model keys to expose in `models`.
The direct integration uses each model's `claudeBehavesAs` as its gateway
alias, sharing the mapping used by Claude Code. All clients use `displayName`.

## Agent outputs

| Module | Generated command/configuration |
| --- | --- |
| Claude Code | One `cc-<provider>-<model>` wrapper per enabled provider model. The provider's optional `effortLevel` is exported as `CLAUDE_CODE_EFFORT_LEVEL`. A generated `modelPicker` lineup in `~/.claude/settings.json` maps each exposed model ID onto a built-in model via `behavesAs`. |
| Codex | `codex` plus one `codex-<provider>` wrapper per enabled provider. Profiles and generated catalogs are installed below `$XDG_CONFIG_HOME/codex`; `~/.codex` is linked there. |
| OMP | `~/.omp/agent/models.yml` and `config.yml`; model thinking entries carry the declared efforts and default level. |
| Pi | `~/.pi/agent/models.json` and `settings.json`; supported Pi levels are mapped from each model's declared effort list. |
| Reasonix | `$XDG_CONFIG_HOME/reasonix/config.toml` for its default provider, currently DeepSeek. Activation and the CLI wrapper refresh the managed key in its protected `.env`, retaining other keys and comments. |

Codex's adapter declares the required catalog fields and client behavior directly
in Nix. Model IDs, limits, modalities, reasoning levels, and capability overrides
come from the provider registry. The generated catalogs remain necessary for
third-party model names; they are not copies of an OpenAI model's capabilities.

At build time, `codex debug models --bundled` exports the installed client's
catalog offline. The adapter extracts `base_instructions` from its official
default model and adds that prompt to each generated entry. Instructions follow
the locked Codex package version, without maintaining a JSON baseline or a second
copy in `model_messages`. OpenAI-specific tool modes are not inherited. This
requires the Codex package to run on the build machine.

Codex and Reasonix configurations use Nix's native TOML generator, so provider
names, model lists, paths, and optional settings are serialized as data.
Claude Code's model picker deduplicates identical rows across providers, and its
wrappers stop if their provider secret cannot be read. Claude Desktop requires
explicit model keys and Claude mappings; invalid entries fail evaluation instead
of disappearing from the generated configuration. Its default effort follows
the selected model's `thinking.default`.

## Claude Code model mapping

Claude Code checks every model ID against the model catalog compiled into the
release. A third-party ID is not in that catalog, so an unmapped session prints
`"<id>" isn't described by this version's model catalog`, writes a
`[claude-code:unrecognized_model]` diagnostic line, and treats the model as
unknown for prompt assembly and for the auto-compact window it assumes.

`claudeBehavesAs` names a built-in Claude model whose client-side handling
the third-party model borrows. The Claude Code module turns each declared
mapping into a `modelPicker` row, which is the only settings source that
carries `behavesAs` and is honored from user settings. Rows are matched
case-insensitively with any `[1m]` suffix stripped, so one row covers both the
bare ID and its `[1m]` spelling, and the ID sent to the provider never changes.

Pick the built-in model with the closest capability tier, preferring a recent
release: an Opus-class ID for a provider's flagship and a Sonnet-class ID for
everything else. Haiku-class targets carry no effort levels, so mapping a model
that declares its own efforts onto one drops them.

A resolved mapping changes which context window Claude Code assumes: a model
without a mapping follows `CLAUDE_CODE_MAX_CONTEXT_TOKENS`, while a mapped model
ignores it and falls back to the default window. Claude Code's adapter generates
the `[1m]` suffix from `contextWindow >= 950000`, independently of
`claudeBehavesAs`; the registry has no separate 1M flag.

## Adding or changing a model

1. Add or update the model in `_providers/<provider>.nix`, including its documented input
   modalities and exact reasoning efforts.
2. Set `claudeBehavesAs` to a built-in Claude model the current Claude Code
   release knows.
3. Declare the agent settings and endpoints, and choose the provider default
   model. Keep non-Claude agents on OpenAI-compatible endpoints.
4. Add an agenix secret under `secrets/` and register it in `secrets/secrets.nix`.
5. Run `just fmt` and `just check`.

New Nix files must be staged with `git add` before flake evaluation. The files
in this directory deliberately share the registry; do not duplicate provider
URLs, credential paths, model IDs, or capability lists in an agent module.
