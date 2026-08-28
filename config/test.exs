import Config

config :petal_boilerplate, :mcp_transport,
  allowed_hosts: [
    "www.example.com",
    "localhost",
    "127.0.0.1",
    "::1",
    "llmcatalog.dev",
    "www.llmcatalog.dev",
    "llmdb.xyz",
    "www.llmdb.xyz"
  ],
  allowed_origins: ["http://www.example.com", "https://www.example.com"]

config :petal_boilerplate, PetalBoilerplate.Catalog.Trending, enabled: false

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :petal_boilerplate, PetalBoilerplate.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "petal_boilerplate_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :petal_boilerplate, PetalBoilerplateWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "twi598leTbcJNAxvKitZGPMr8ZDu9ONMsUY1vk6ubAxy5Dmzx/7QrR9at+voP4X2",
  server: false

config :petal_boilerplate,
  canonical_host: nil,
  enable_analytics: false,
  seo_indexing_enabled: true,
  sync_history_on_start: false

# In test we don't send emails.
config :petal_boilerplate, PetalBoilerplate.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
