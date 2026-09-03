# LLM Catalog

Browse and compare LLM model metadata at [llmcatalog.dev](https://llmcatalog.dev).
The catalog is powered by the [llm_db](https://github.com/agentjido/llmdb) Elixir package.

Browse and compare LLM models with capability-aware filtering.

## Features

- Browse models from all major LLM providers (OpenAI, Anthropic, Google, Mistral, and more)
- Filter by capabilities (chat, tools, JSON, streaming, reasoning, embeddings)
- Filter by input modalities (text, image, audio)
- Filter by context window, output limits, and pricing
- Sort by any column
- Mobile-friendly card view
- Dark mode support

## Powered by llm_db

This site is powered by [llm_db](https://hex.pm/packages/llm_db), an Elixir package providing LLM model metadata with fast, capability-aware lookups.

Add it to your project:

```elixir
def deps do
  [
    {:llm_db, "~> 2026.9"}
  ]
end
```

This site consumes the published Hex release in [`mix.exs`](mix.exs), with the committed lockfile pinning the exact `llm_db` build. On startup, the app syncs the matching published history bundle into a local cache so the history UI and API stay available.

### Example Usage

```elixir
# List all providers
LLMDb.provider()

# List all models
LLMDb.model()

# Find models with specific capabilities
LLMDb.model()
|> Enum.filter(fn model ->
  caps = model.capabilities || %{}
  caps[:chat] and get_in(caps, [:tools, :enabled])
end)
```

## Development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+

### Setup

```bash
# Install dependencies
mix deps.get

# Build assets
mix assets.build

# Start the server
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000) to see the app.

### Running in IEx

```bash
iex -S mix phx.server
```

## Deployment

The application is configured for deployment to standard Phoenix hosting platforms.

### Environment Variables

- `SECRET_KEY_BASE` - Required for production
- `PHX_HOST` - The public hostname (production: `llmcatalog.dev`)
- `CANONICAL_HOST` - The hostname used for permanent redirects
- `PORT` - The port to listen on (default: 4000)
- `ENABLE_ANALYTICS` - Set to `true`, `1`, or `yes` to enable Plausible analytics; all other values disable it

When analytics are enabled, the model catalog sends these custom events through the first-party Plausible proxy:

- `Model Search` - Allowlisted catalog value, active filter state, and result count
- `Model Filter` - Changed control, active filter state, sort state, and result count

Search analytics use an exact allowlist generated from the current catalog. Exact provider names or IDs are sent as canonical `provider:<name>` values. Exact model names or IDs are sent as canonical `model:<name>` values. Blank searches are sent as `none`. All partial, unknown, or arbitrary text is sent only as `other`; unmatched raw text is never sent. Configure the event goals and custom properties in the Plausible site settings after the first events arrive.

## License

Apache-2.0
