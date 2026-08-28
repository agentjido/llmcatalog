# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :petal_boilerplate,
  api_rate_limit: [limit: 120, window_seconds: 60],
  ecto_repos: [],
  history_module: PetalBoilerplate.History,
  legacy_hosts: ["llmdb.xyz", "www.llmdb.xyz"],
  sync_history_on_start: true

config :petal_boilerplate, :mcp_transport,
  allowed_hosts: ["llmcatalog.dev", "www.llmcatalog.dev", "llmdb.xyz", "www.llmdb.xyz"],
  allowed_origins: [
    "https://llmcatalog.dev",
    "https://www.llmcatalog.dev",
    "https://llmdb.xyz",
    "https://www.llmdb.xyz"
  ]

config :petal_boilerplate, PetalBoilerplate.Catalog.Trending,
  enabled: true,
  refresh_interval_ms: :timer.hours(6)

config :petal_boilerplate, :plausible_proxy,
  site_domain: "llmcatalog.dev",
  script_path: "/_q/s.js",
  event_path: "/_q/e",
  script_url: "https://plausible.io/js/pa--janBeogK9G9oaeuCbmPP.js",
  event_url: "https://plausible.io/api/event"

# Configures the endpoint
config :petal_boilerplate, PetalBoilerplateWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PetalBoilerplateWeb.ErrorHTML, json: PetalBoilerplateWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PetalBoilerplate.PubSub,
  live_view: [signing_salt: "8Hv+cWMw"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :petal_boilerplate, PetalBoilerplate.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.24.2",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :petal_components,
       :error_translator_function,
       {PetalBoilerplateWeb.CoreComponents, :translate_error}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
