defmodule PetalBoilerplateWeb.Router do
  use PetalBoilerplateWeb, :router

  pipeline :browser do
    plug PetalBoilerplateWeb.Plugs.LLMAcceptCompat
    plug :accepts, ["html"]
    plug PetalBoilerplateWeb.Plug.RequestAudit
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PetalBoilerplateWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PetalBoilerplateWeb.Plugs.LLMResponse
  end

  pipeline :model_page do
    plug PetalBoilerplateWeb.Plugs.ModelExists
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PetalBoilerplateWeb.Plug.RequestAudit
    plug PetalBoilerplateWeb.Plugs.RateLimit
    plug PetalBoilerplateWeb.Plugs.APIVersion
  end

  scope "/", PetalBoilerplateWeb do
    pipe_through :browser

    live "/", ModelLive, :index
    live "/llm-models", LLMModelsLive, :index
    live "/rankings/cheapest-llm-api", CatalogLandingLive, :cheapest
    live "/rankings/free-llm-api", CatalogLandingLive, :free
    live "/rankings/ai-models", CatalogLandingLive, :ai_models
    live "/models/vision", CatalogLandingLive, :vision
    live "/models/tool-calling", CatalogLandingLive, :tool_calling
    live "/models/long-context", CatalogLandingLive, :long_context
    live "/models/open-weights", CatalogLandingLive, :open_weights
    live "/models/video", CatalogLandingLive, :video
    live "/history", HistoryLive, :index
    live "/about", AboutLive, :index
    live "/contact", ContactLive, :index
    live "/developers", DevelopersLive, :index
    live "/privacy", PrivacyLive, :index

    get "/robots.txt", DiscoveryController, :robots
    get "/sitemap.xml", DiscoveryController, :sitemap
    get "/llms.txt", DiscoveryController, :llms
    get "/feed", DiscoveryController, :feed
    get "/.well-known/ard.json", DiscoveryController, :ard
    get "/.well-known/ai-catalog.json", DiscoveryController, :ard
    get "/.well-known/agent-skills/index.json", DiscoveryController, :agent_skills
    get "/.well-known/agent-skills/llm-catalog/SKILL.md", DiscoveryController, :agent_skill
    get "/.well-known/mcp/server-card.json", DiscoveryController, :mcp_server_card
    get "/.well-known/api-catalog", DiscoveryController, :api_catalog

    # OG image endpoints (PNG images for social sharing)
    get "/og/default.png", OGImageController, :default
    get "/og/home.png", OGImageController, :home
    get "/og/about.png", OGImageController, :about
    get "/og/model/:provider/*id", OGImageController, :model
  end

  scope "/", PetalBoilerplateWeb do
    pipe_through [:browser, :model_page]

    live "/models/:provider/*id", ModelLive, :show
  end

  # Other scopes may use custom stacks.
  scope "/", PetalBoilerplateWeb do
    pipe_through :api

    get "/openapi.json", OpenAPIController, :show
  end

  scope "/api", PetalBoilerplateWeb do
    pipe_through :api

    get "/v1/history/recent", HistoryController, :recent
    get "/v1/history/:provider/*id", HistoryController, :model
    get "/history/recent", HistoryController, :recent
    get "/history/:provider/*id", HistoryController, :model
    get "/mcp/server-card", DiscoveryController, :mcp_server_card
    match :*, "/*path", APIErrorController, :not_found
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:petal_boilerplate, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PetalBoilerplateWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", PetalBoilerplateWeb do
    pipe_through :browser

    match :*, "/*path", ErrorController, :not_found
  end
end
