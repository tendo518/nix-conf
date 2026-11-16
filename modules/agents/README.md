# Agent configuration

Three separate inputs feed the client modules:

- **Model facts** in `_models/`: names, modalities, reasoning/tool support, and
  token limits. No endpoints, credentials, prices, or client compatibility hints.
- **Connections** in `_providers.nix`: local endpoints, secret names, API model IDs,
  and references to model facts.
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

`_models/models-dev.json` is a checked-in, selected snapshot of
<https://models.dev/models.json>. It does **not** use models.dev's provider
catalog. Model IDs such as `alibaba/qwen3.8-27b` identify the originating model,
not the local connection used to serve it.

Only these model fields are imported:

- `name`, optional `description`
- `reasoning`, `tool_call`
- `modalities`
- `limit.context`, optional `limit.input` and `limit.output`

The snapshot retains the upstream limits and modalities. For example,
GPT-6.1 Sol has a 1,050,000-token context; there is no separate local 272K cap.
These are model capabilities, not a guarantee that every deployment serves the
full window. There is deliberately no per-provider capability override system.

Models absent from the independent catalog live in `_models/local.nix` under
explicit `local/` keys. Currently these are Qwen4 Max Preview and Step Router V1.
Their declarations are local knowledge, not inferred from a similar model or
another provider. The router is not treated as a specific foundation model.

Refresh the snapshot with:

```bash
scripts/update-agent-models.py
# Or use an already downloaded models.json without network access:
scripts/update-agent-models.py --source /path/to/models.json
```

The updater reads all references from `_providers.nix`, deduplicates
shared models, skips `local/` declarations, and writes only referenced upstream
facts. Missing upstream models fail instead of triggering a fuzzy match or
preserving stale data. Review the resulting diff before switching.

Only the updater uses the network. Nix evaluation and agent startup read the
committed snapshot offline; they do not fetch models.dev.

## Connections

A provider model has exactly two fields:

```nix
{
  name = "OpenAI";
  secret = "openai-api-key";
  endpoints.openai = "https://api.openai.com/v1";
  defaultModel = "sol";
  models.sol = {
    id = "gpt-6.1-sol";           # ID sent to this connection
    model = "openai/gpt-6.1-sol"; # Model facts to use
  };
}
```

The same model facts can serve several connections with different API IDs.
Aliases are explicit: `deepseek-flash`, for example, references the declared
`deepseek/deepseek-v4.1-flash-1017` model. No ID is guessed from a display name.

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
reads the local model/provider declarations, resolves references and defaults,
and attaches runtime secret paths. Each client passes its own `_agents.nix`
settings. The helper exposes:

- `selected`: enabled providers. Each model contains its facts plus the API
  `id`; each provider has `agentConfig`, `defaultModelKey`, and the resolved
  `defaultModel` record.
- `defaultProvider`, `defaultModel`: the global choice, evaluated only when a
  client needs it. Pi, OMP, Reasonix, and Claude Desktop require one enabled
  `default = true`; wrapper-based clients need no global default.
- `ageSecrets`: declarations for enabled providers only.

Agent `defaultModel` overrides use the provider-local model key. Claude Code's
optional `smallModel` falls back to that resolved default. Codex keeps official
OpenAI login for the base `codex` command and uses API-key profiles for configured
connections; `openai` uses the non-reserved provider ID `openai-api`.

## Client output

- **Pi / OMP** declare their own small serializers directly. They receive names, limits,
  `reasoning`, and the intersection of model inputs with their `text`/`image`
  schema. PDF/video capabilities remain in the model facts, not in invalid
  client configuration fields.
- **Reasoning controls** use client/server defaults. The independent model feed
  does not supply effort lists, so we do not invent them, declare `ultra`, or
  emit thinking-level maps. Claude Code's explicit effort preference, if any,
  belongs to agent policy, not model facts.
- **Codex** gets the required custom model catalogs and instructions extracted
  offline from the installed client's bundled catalog. Custom catalogs expose
  no guessed effort levels, parallel calls, verbosity control, original-image
  detail, or built-in search support. API-key profiles disable built-in web
  search. The official-login catalog is unchanged.
- **Claude Code / Desktop** use actual API model IDs. There are no `behavesAs`
  mappings, Claude-name substitutions, or synthetic `[1m]` suffixes. Code gets
  the declared context through `CLAUDE_CODE_MAX_CONTEXT_TOKENS`; Desktop gets
  its native `supports1m` field. The gateway must accept the actual model IDs.
- **Reasonix** uses the default connection and its declared token limits. Its
  activation/wrapper refresh the protected `.env`, preserving unrelated keys.
- **DSH** uses its native DeepSeek Messages adapter (`deepseek-official`), plus
  the bundled pi-ai adapter for OpenAI (Responses) and Qwen Token Plan (Chat
  Completions). Model names, limits, and text/image inputs come from the same
  model facts. No effort lists are synthesized; native adapter/catalog defaults
  apply. Home activation seeds DSH's native local credential store
  (`~/.dsh/.credentials.yaml`) from the enabled agenix secrets; generated
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

To add a model, add a provider reference, refresh the snapshot (or write an
explicit `local/` declaration), and enable the connection for the intended
agents. Add new connections directly to `_providers.nix` and register their
encrypted secrets in `secrets/secrets.nix`.

```bash
just fmt
nix build .#checks.x86_64-linux.agent-config
nix flake check --no-build --all-systems
```

The check covers pure resolution, schema boundaries, model references, client
serialization, and the updater's selection/deduplication/failure behavior.
It does not test credentials, remote deployment limits, or API availability.
New files must be staged with `git add` before flake evaluation.
