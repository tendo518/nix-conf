# Agent configuration

Three separate inputs feed the client modules:

- **Model facts** in `_models/`: names, modalities, reasoning/tool support, and
  token limits. Explicitly selected models use matching models.dev provider
  entries; unmatched services use local facts. No endpoints, credentials, prices,
  or client hints.
- **Connections** in `_providers.nix`: local endpoints, secret names, defaults,
  explicit model ID lists, and the Chat Completions thinking dialect.
  `modelsDevProvider` identifies the source for subscribed model facts; it does
  not expose the provider's entire catalog.
- **Agent policy** in `_agents.nix`: enabled connections, defaults, wire APIs,
  profiles, and other client preferences.

```text
_models/ + _providers.nix + _agents.nix
                 ↓
          _context.nix          select, resolve, attach secret paths
                 ↓
     pi.nix / omp.nix / ...     native format, package, install
```

Private paths start with `_` so `import-tree` does not expose them as selectable
modules. All existing `agents/*` Home Manager module names remain unchanged.

## Model facts

`_models/models-dev.json` is a checked-in snapshot of explicitly selected models
from <https://models.dev/api.json>. Its keys are local connection names, then
the actual API model IDs. The updater imports these model fields:

- `name`, optional `description`
- `reasoning`, optional `reasoning_options`, `tool_call`
- `modalities`
- `limit.context`, optional `limit.input` and `limit.output`

The snapshot retains the selected provider entry's limits, modalities, and
reasoning options. For example, GPT-6.2 Sol has a 1,050,000-token context; there is no separate
local 272K cap. These are serving-connection capabilities, not a guarantee that
every deployment serves the full window.

Services without a matching models.dev provider entry declare their models in
`_models/local.nix` under explicit `local/` keys. Currently these are the GPU
Qwen endpoint and Qwen4 Max on the local Token Plan gateway. Their declarations
are local knowledge, not inferred from a similar model or another provider.

Refresh the snapshot with:

```bash
scripts/update-agent-models.py
# Or use an already downloaded api.json without network access:
scripts/update-agent-models.py --source /path/to/api.json
```

The updater reads each explicit model ID from `_providers.nix`. For a non-local
ID, it uses `modelsDevProvider` to select one provider entry. Local IDs are
skipped. Missing providers or models
fail instead of preserving stale data. Review the resulting diff before switching.

Only the updater uses the network. Nix evaluation and agent startup read the
committed snapshot offline; they do not fetch models.dev.

## Connections

A connection lists only the models it actually serves:

```nix
{
  name = "OpenAI";
  modelsDevProvider = "openai";
  secret = "openai-api-key";
  endpoints.openai = "https://api.openai.com/v1";
  defaultModel = "gpt-6.2-sol";
  models = [
    "gpt-6.2-sol"
  ];
}
```

Each list item is the API model ID. A local exception uses its `local/...` key;
the local declaration supplies the actual wire ID. No ID is guessed from a
display name.

Secrets are declared from `secrets/<secret>.age`. Plaintext keys are read at
runtime and are never copied into the model snapshot or generated store files.

## Agent policy and resolution

An omitted provider is disabled. Listed entries require a boolean `enable`;
unknown provider names are rejected, including disabled misspellings.

```nix
pi = {
  deepseek = { enable = true; default = true; };
  openai = { enable = true; api = "openai-responses"; };
};
```

`_context.nix` is the only shared helper. It accepts `{ lib, config, settings }`,
reads the selected and local model facts, resolves defaults, and attaches
runtime secret paths. Each client passes its own `_agents.nix`
settings. The helper exposes:

- `selected`: enabled providers. Each model contains its facts and API `id`;
  each provider has `agentConfig`, `defaultModelKey`, and the resolved
  `defaultModel` record.
- `defaultProvider`, `defaultModel`: the global choice, evaluated only when a
  client needs it. Pi, OMP, Reasonix, and Claude Desktop require one enabled
  `default = true`; wrapper-based clients need no global default.
- `ageSecrets`: declarations for enabled providers only.

Agent `defaultModel` overrides use the API model ID.
Claude Code's optional `smallModel` falls back to that resolved default. Codex
keeps official OpenAI login for the base `codex` command and uses API-key profiles for configured
connections; `openai` uses the non-reserved provider ID `openai-api`.

## Client output

- **Pi / OMP** declare their own small serializers directly. They receive names, limits,
  `reasoning`, and the intersection of model inputs with their `text`/`image`
  schema. PDF/video capabilities remain in the model facts, not in invalid
  client configuration fields.
- **Reasoning controls** come from the selected or local model's
  `reasoning_options` when available. Pi emits `thinkingLevelMap`; OMP emits
  `thinking.efforts` and maps its `minimal` selector to a supported `none` wire
  value; DSH emits only supported `reasoningEfforts` entries. Chat Completions
  adapters receive the connection's thinking dialect: Qwen uses
  `enable_thinking` plus effort, DeepSeek uses `thinking.type` plus effort, and
  GLM uses the Z.ai-style thinking object. OMP detects DeepSeek from its endpoint
  because its configuration schema has no explicit DeepSeek format value.
  Responses connections use `reasoning.effort` directly. Unmapped connections
  use client/server defaults. Claude Code's explicit effort preference belongs
  to agent policy.
- **Codex** gets the required custom model catalogs and instructions extracted
  offline from the installed client's bundled catalog. Custom catalogs expose
  declared effort levels, but no guessed parallel calls, verbosity control,
  original-image detail, or built-in search support. API-key profiles disable
  built-in web search. The official-login catalog is unchanged.
- **Claude Code / Desktop** use actual API model IDs. There are no `behavesAs`
  mappings, Claude-name substitutions, or synthetic `[1m]` suffixes. Code gets
  the declared context through `CLAUDE_CODE_MAX_CONTEXT_TOKENS`; Desktop gets
  its native `supports1m` field. The gateway must accept the actual model IDs.
- **Reasonix** uses the default connection, its declared token limits, and its
  supported effort list. It selects the matching reasoning protocol explicitly.
  Its activation/wrapper refresh the protected `.env`, preserving unrelated keys.
- **DSH** uses its native DeepSeek Messages adapter (`deepseek-official`), plus
  the bundled pi-ai adapter for OpenAI (Responses) and Qwen Token Plan (Chat
  Completions). Model names, limits, and text/image inputs come from the same
  model facts. Declared effort lists are translated to the pi-ai adapter;
  unmapped models use native adapter/catalog defaults. Home activation seeds
  DSH's native local credential store (`~/.dsh/.credentials.yaml`) from the
  enabled agenix secrets; generated
  configuration contains only their credential names.

### DSH usage

`agents/dsh` installs DSH and its plugin-manager dependency, pnpm. Start the Web
UI with `dsh web`, or use `dsh headless --help` for the headless interface.
In the Web UI, choose a configured model from the model picker.

Home Manager owns `~/.dsh/cordis.patch.yml`, which applies the provider declarations
above every profile's own patch. Change these providers in `_agents.nix` or
`_providers.nix`, not in the Models settings page: DSH refuses UI edits shadowed
by the home-level patch. Other profile settings remain editable. The bundled
DeepSeek Flash default is left unpatched so the picker can save a different
default for new sessions. Existing sessions retain their selected model.

DSH's credential store is shared by the CLI, Web UI, TUI, and Desktop app, so
the agenix keys work without exporting them in a GUI launch environment. The
CLI and Desktop app both run the packaged DSH directly; Home Manager refreshes
the shared store during activation. DSH watches the file and applies changed
keys to the next request, including while the Desktop app is running.

DSH defaults to `~/.dsh`. A custom `DSH_HOME` needs the same `cordis.patch.yml`
(or an explicit `--patch ~/.dsh/cordis.patch.yml`) and agenix-managed
`.credentials.yaml`. Keys saved through DSH's Models page remain useful for
providers not managed by this module; activation overwrites the references for
enabled agenix providers. Rotated agenix keys are picked up by the next
activation. DSH stores the values in an owner-only file; its maintainers note
that an OS-keychain credential provider is not yet shipped.

Client serialization, runtime settings, wrappers, and activation all live in the
corresponding `*.nix` module. A little repetition is preferable to an adapter
framework: reading one client should not require following formatter files.
There is no `_lib` directory or common schema for unrelated client settings.

## Changes and checks

To add a model, add its explicit connection reference, set `modelsDevProvider`
when its facts come from models.dev, and refresh the snapshot. For an unmatched
service, write an explicit `local/` declaration and reference it from the connection.
Add new connections directly to `_providers.nix` and register their
encrypted secrets in `secrets/secrets.nix`.

```bash
just fmt
nix build .#checks.x86_64-linux.agent-config
nix flake check --no-build --all-systems
```

The check covers pure resolution, schema boundaries, local references, client
serialization, and the updater's model selection/failure behavior.
It does not test credentials, remote deployment limits, or API availability.
New files must be staged with `git add` before flake evaluation.
