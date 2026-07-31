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
    assert body =~ "Sitemap: #{PublicRoutes.absolute("/sitemap.xml")}"
    refute body =~ "Disallow: /"
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
             "/llm-models",
             "/rankings/ai-models",
             "/rankings/cheapest-llm-api",
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
    refute body =~ "/history"

    for route <- LandingPages.routes() do
      assert body =~ PublicRoutes.absolute(route)
    end
  end

  test "llms.txt documents Markdown, discovery, and MCP interfaces", %{conn: conn} do
    conn = get(conn, "/llms.txt")
    body = response(conn, 200)

    assert body =~ "Accept: text/markdown"
    assert body =~ PublicRoutes.absolute("/sitemap.xml")
    assert body =~ PublicRoutes.absolute("/feed")
    assert body =~ PublicRoutes.absolute("/llm-models")
    assert body =~ PublicRoutes.absolute("/rankings/ai-models")
    assert body =~ PublicRoutes.absolute("/rankings/cheapest-llm-api")
    assert body =~ PublicRoutes.absolute("/models/vision")
    assert body =~ PublicRoutes.absolute("/models/tool-calling")
    assert body =~ PublicRoutes.absolute("/models/long-context")
    assert body =~ PublicRoutes.absolute("/models/open-weights")
    assert body =~ PublicRoutes.absolute("/models/video")
    assert body =~ PublicRoutes.absolute("/api/mcp")
    assert body =~ "query_models"
    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
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
