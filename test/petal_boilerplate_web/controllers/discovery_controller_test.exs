defmodule PetalBoilerplateWeb.DiscoveryControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO
  alias PetalBoilerplate.Catalog.LandingPages

  defmodule FeedHistory do
    def recent(50) do
      {:ok,
       [
         %{
           "captured_at" => "2026-07-25T03:25:01Z",
           "changes" => [
             %{"op" => "replace", "path" => "limits.context"}
           ],
           "event_id" => "stable-event-id",
           "model_id" => "gpt-4o",
           "provider" => "openai",
           "type" => "changed"
         }
       ]}
    end
  end

  defmodule EmptyHistory do
    def recent(50), do: {:error, :unavailable}
  end

  setup do
    indexing = Application.get_env(:petal_boilerplate, :seo_indexing_enabled)
    history = Application.get_env(:petal_boilerplate, :history_module)

    on_exit(fn ->
      Application.put_env(:petal_boilerplate, :seo_indexing_enabled, indexing)
      Application.put_env(:petal_boilerplate, :history_module, history)
    end)

    :ok
  end

  test "production robots allows crawling and names the curated sitemap", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :seo_indexing_enabled, true)

    conn = get(conn, "/robots.txt")
    body = response(conn, 200)

    assert body =~ "User-agent: *"
    assert body =~ "Allow: /"
    assert body =~ "User-agent: OAI-SearchBot\nAllow: /"
    assert body =~ "User-agent: ClaudeBot\nDisallow: /"
    assert body =~ "User-agent: GPTBot\nDisallow: /"
    assert body =~ "User-agent: Claude-SearchBot\nAllow: /"
    assert body =~ "User-agent: Claude-User\nAllow: /"
    assert body =~ "User-agent: PerplexityBot\nAllow: /"
    assert body =~ "User-agent: Perplexity-User\nAllow: /"
    assert body =~ "User-agent: Google-Extended\nDisallow: /"
    assert body =~ "User-agent: CCBot\nDisallow: /"
    assert body =~ "User-agent: Bytespider\nDisallow: /"
    assert body =~ "Sitemap: #{PublicRoutes.absolute("/sitemap.xml")}"
    refute body =~ "Disallow: /models/"
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"
  end

  test "staging robots blocks all crawling", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :seo_indexing_enabled, false)

    body =
      conn
      |> get("/robots.txt")
      |> response(200)

    assert body =~ "Disallow: /"
    refute body =~ "Sitemap:"
  end

  test "machine discovery routes accept their declared media types" do
    for {path, accept} <- [
          {"/robots.txt", "text/plain"},
          {"/sitemap.xml", "application/xml"},
          {"/llms.txt", "text/plain"},
          {"/feed", "application/rss+xml"},
          {"/.well-known/ard.json", "application/json"},
          {"/.well-known/agent-skills/index.json", "application/json"},
          {"/.well-known/agent-skills/llm-catalog/SKILL.md", "text/markdown"},
          {"/.well-known/mcp.json", "application/json"},
          {"/.well-known/mcp/server-card.json", "application/mcp-server-card+json"},
          {"/.well-known/api-catalog", "application/linkset+json"}
        ] do
      conn = build_conn() |> put_req_header("accept", accept) |> get(path)
      assert response(conn, 200), "expected #{path} to accept #{accept}"
    end
  end

  test "sitemap contains only approved search landing pages in stable order", %{conn: conn} do
    body =
      conn
      |> get("/sitemap.xml")
      |> response(200)

    assert body =~ ~s(<?xml version="1.0" encoding="UTF-8"?>)
    assert body =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)

    assert {:xmlElement, _, _, _, _, _, _, _, _, _, _, _} =
             body |> String.to_charlist() |> :xmerl_scan.string() |> elem(0)

    refute body =~ "<priority>"
    refute body =~ "<changefreq>"

    locations =
      Regex.scan(~r/<loc>(.*?)<\/loc>/, body, capture: :all_but_first)
      |> Enum.map(fn [location] -> location end)

    expected_locations =
      Enum.map(SEO.search_indexable_paths(), &PublicRoutes.absolute/1)

    lastmods =
      Regex.scan(~r/<lastmod>(.*?)<\/lastmod>/, body, capture: :all_but_first)
      |> Enum.map(fn [lastmod] -> lastmod end)

    expected_lastmods =
      SEO.search_indexable_entries()
      |> Enum.map(fn %{lastmod: lastmod} -> Date.to_iso8601(lastmod) end)

    assert SEO.search_indexable_paths() == [
             "/",
             "/about",
             "/contact",
             "/developers",
             "/llm-models",
             "/privacy",
             "/rankings/ai-models",
             "/rankings/cheapest-llm-api",
             "/rankings/free-llm-api",
             "/models/vision",
             "/models/tool-calling",
             "/models/long-context",
             "/models/open-weights",
             "/models/video"
           ]

    assert locations == expected_locations
    assert lastmods == expected_lastmods
    assert length(lastmods) == length(locations)
    assert Enum.all?(lastmods, &match?({:ok, _date}, Date.from_iso8601(&1)))

    {:ok, catalog_generated_at, _offset} =
      DateTime.from_iso8601(LLMDB.Packaged.snapshot()["generated_at"])

    expected_developers_lastmod =
      Enum.max([~D[2026-08-28], DateTime.to_date(catalog_generated_at)], Date)

    assert Enum.find(SEO.search_indexable_entries(), &(&1.path == "/developers")).lastmod ==
             expected_developers_lastmod

    refute body =~ "/history"

    for route <- LandingPages.routes() do
      assert body =~ PublicRoutes.absolute(route)
    end
  end

  test "llms.txt documents use guidance and developer interfaces", %{conn: conn} do
    conn = get(conn, "/llms.txt")
    body = response(conn, 200)

    assert body =~ "Accept: text/markdown"
    assert body =~ PublicRoutes.absolute("/sitemap.xml")
    assert body =~ PublicRoutes.absolute("/feed")
    assert body =~ PublicRoutes.absolute("/llm-models")
    assert body =~ PublicRoutes.absolute("/rankings/ai-models")
    assert body =~ PublicRoutes.absolute("/rankings/cheapest-llm-api")
    assert body =~ PublicRoutes.absolute("/rankings/free-llm-api")
    assert body =~ PublicRoutes.absolute("/models/vision")
    assert body =~ PublicRoutes.absolute("/models/tool-calling")
    assert body =~ PublicRoutes.absolute("/models/long-context")
    assert body =~ PublicRoutes.absolute("/models/open-weights")
    assert body =~ PublicRoutes.absolute("/models/video")
    assert body =~ PublicRoutes.absolute("/api/mcp")
    assert body =~ PublicRoutes.absolute("/.well-known/mcp.json")
    assert body =~ PublicRoutes.absolute("/api/v1/history/recent")
    assert body =~ PublicRoutes.absolute("/developers")
    assert body =~ PublicRoutes.absolute("/openapi.json")
    assert body =~ PublicRoutes.absolute("/privacy")
    assert body =~ "https://www.npmjs.com/package/@agentjido/llmdb"
    assert body =~ "## When to use this site"
    assert body =~ "## When not to use this site"
    assert body =~ "MCP Streamable HTTP endpoint"
    assert body =~ "2026-07-28"
    assert body =~ "2025-11-25"
    assert body =~ "server/discover"
    assert body =~ "query_models"
    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
  end

  test "well-known documents advertise the API, MCP server, and agent skill", %{conn: conn} do
    ard = conn |> get("/.well-known/ard.json") |> json_response(200)
    assert ard["specVersion"] == "1.0"
    assert Enum.any?(ard["entries"], &(&1["url"] == PublicRoutes.absolute("/openapi.json")))

    skill_index =
      build_conn() |> get("/.well-known/agent-skills/index.json") |> json_response(200)

    [skill] = skill_index["skills"]
    assert skill["name"] == "llm-catalog"
    assert skill["digest"] =~ "sha256:"

    skill_body = build_conn() |> get(skill["url"]) |> response(200)
    assert skill_body =~ "name: llm-catalog"
    assert skill_body =~ "https://llmcatalog.dev/api/mcp"

    digest = :crypto.hash(:sha256, skill_body) |> Base.encode16(case: :lower)
    assert skill["digest"] == "sha256:#{digest}"

    card_conn = build_conn() |> get("/.well-known/mcp/server-card.json")
    server_card = json_response(card_conn, 200)

    assert server_card["name"] == "io.github.agentjido/llmcatalog"
    assert hd(server_card["remotes"])["type"] == "streamable-http"
    assert hd(server_card["remotes"])["supportedProtocolVersions"] |> hd() == "2026-07-28"
    assert hd(server_card["icons"])["src"] == PublicRoutes.absolute("/favicon.ico")

    assert get_resp_header(card_conn, "content-type") |> hd() =~
             "application/mcp-server-card+json"

    endpoint_card = build_conn() |> get("/api/mcp/server-card") |> json_response(200)
    assert endpoint_card == server_card

    compatibility_manifest =
      build_conn() |> get("/.well-known/mcp.json") |> json_response(200)

    assert compatibility_manifest["serverUrl"] == PublicRoutes.absolute("/api/mcp")
    assert compatibility_manifest["transport"] == "streamable-http"
    assert compatibility_manifest["protocolVersion"] == "2026-07-28"

    assert compatibility_manifest["mcpServers"]["llmcatalog"]["url"] ==
             PublicRoutes.absolute("/api/mcp")

    assert Enum.map(compatibility_manifest["tools"], & &1["name"]) == [
             "query_models",
             "get_model",
             "list_providers"
           ]

    assert get_resp_header(build_conn() |> get("/.well-known/mcp.json"), "content-type")
           |> hd() =~ "application/json"

    api_catalog = build_conn() |> get("/.well-known/api-catalog")
    assert response(api_catalog, 200) =~ PublicRoutes.absolute("/openapi.json")
    assert get_resp_header(api_catalog, "content-type") |> hd() =~ "application/linkset+json"
  end

  test "RSS feed uses stable event IDs, dates, and model links", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, FeedHistory)

    conn = get(conn, "/feed")
    body = response(conn, 200)

    assert {:xmlElement, _, _, _, _, _, _, _, _, _, _, _} =
             body |> String.to_charlist() |> :xmerl_scan.string() |> elem(0)

    assert body =~ "<rss"
    assert body =~ ~s(<guid isPermaLink="false">stable-event-id</guid>)
    assert body =~ "<pubDate>Sat, 25 Jul 2026 03:25:01 GMT</pubDate>"
    assert body =~ PublicRoutes.absolute(PublicRoutes.model_path("openai", "gpt-4o"))
    assert get_resp_header(conn, "content-type") |> hd() =~ "application/rss+xml"
    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
  end

  test "RSS feed remains valid when history is unavailable", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, EmptyHistory)

    body =
      conn
      |> get("/feed")
      |> response(200)

    assert {:xmlElement, _, _, _, _, _, _, _, _, _, _, _} =
             body |> String.to_charlist() |> :xmerl_scan.string() |> elem(0)

    assert body =~ "<channel>"
    refute body =~ "<item>"
    refute body =~ "<lastBuildDate>"
  end
end
