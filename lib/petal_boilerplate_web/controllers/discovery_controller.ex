defmodule PetalBoilerplateWeb.DiscoveryController do
  @moduledoc """
  Serves crawler, search, feed, and LLM discovery documents.
  """

  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @feed_limit 50

  def robots(conn, _params) do
    body =
      if SEO.indexing_enabled?() do
        """
        User-agent: *
        Allow: /

        Sitemap: #{PublicRoutes.absolute("/sitemap.xml")}
        """
      else
        """
        User-agent: *
        Disallow: /
        """
      end

    conn
    |> put_resp_content_type("text/plain", "utf-8")
    |> put_resp_header("cache-control", "public, max-age=300")
    |> send_resp(200, body)
  end

  def sitemap(conn, _params) do
    entries =
      SEO.search_indexable_paths()
      |> Enum.map(&sitemap_entry/1)

    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.join(entries, "\n")}
    </urlset>
    """

    conn
    |> put_resp_content_type("application/xml", "utf-8")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, body)
  end

  def llms(conn, _params) do
    endpoint_url = PetalBoilerplateWeb.Endpoint.url()

    body = """
    # LLM Model Database

    llmdb.xyz is a public catalog for browsing and comparing large language models.

    ## Preferred retrieval

    - Request the canonical page with `Accept: text/markdown`.
    - Or append `.md` to a supported public route.
    - Use `/index.md` for the home page.

    ## Public content

    - Catalog: #{endpoint_url}/
    - Deduplicated LLM models list: #{endpoint_url}/llm-models
    - AI model rankings: #{endpoint_url}/rankings/ai-models
    - Cheapest LLM APIs: #{endpoint_url}/rankings/cheapest-llm-api
    - Vision LLM models: #{endpoint_url}/models/vision
    - Tool-calling LLM models: #{endpoint_url}/models/tool-calling
    - Largest context window LLMs: #{endpoint_url}/models/long-context
    - Open-weight LLM models: #{endpoint_url}/models/open-weights
    - Video AI models: #{endpoint_url}/models/video
    - About: #{endpoint_url}/about
    - Recent history: #{endpoint_url}/history
    - Model pages: #{endpoint_url}/models/:provider/:model_id

    ## Discovery

    - Sitemap: #{endpoint_url}/sitemap.xml
    - RSS history feed: #{endpoint_url}/feed

    ## MCP

    - HTTP endpoint: #{endpoint_url}/api/mcp
    - Tools: `query_models`, `get_model`, `list_providers`

    Markdown copies are retrieval alternatives. Their response headers identify the canonical HTML page and prevent duplicate indexing.
    """

    conn
    |> put_resp_content_type("text/plain", "utf-8")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> put_resp_header("x-robots-tag", "noindex")
    |> send_resp(200, body)
  end

  def feed(conn, _params) do
    events =
      case history_module().recent(@feed_limit) do
        {:ok, events} -> events
        _ -> []
      end

    items = Enum.map_join(events, "\n", &feed_item/1)
    last_build_date = feed_last_build_date(events)

    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>llmdb.xyz Model History</title>
        <description>Recent model metadata changes from the LLM Model Database.</description>
        <link>#{xml_escape(PublicRoutes.absolute("/history"))}</link>
        <atom:link href="#{xml_escape(PublicRoutes.absolute("/feed"))}" rel="self" type="application/rss+xml" />
        <language>en-us</language>
    #{last_build_date}#{items}
      </channel>
    </rss>
    """

    conn
    |> put_resp_content_type("application/rss+xml", "utf-8")
    |> put_resp_header("cache-control", "public, max-age=300")
    |> put_resp_header("x-robots-tag", "noindex")
    |> send_resp(200, body)
  end

  defp sitemap_entry(path) do
    "  <url><loc>#{xml_escape(PublicRoutes.absolute(path))}</loc></url>"
  end

  defp feed_item(event) do
    provider = map_get(event, "provider", :provider) || "unknown"
    model_id = map_get(event, "model_id", :model_id) || "unknown"
    event_type = map_get(event, "type", :type) || "changed"
    event_id = map_get(event, "event_id", :event_id) || "#{provider}:#{model_id}:#{event_type}"
    captured_at = map_get(event, "captured_at", :captured_at)
    title = "#{Phoenix.Naming.humanize(event_type)}: #{provider}:#{model_id}"
    link = PublicRoutes.absolute(PublicRoutes.model_path(provider, model_id))

    """
        <item>
          <title>#{xml_escape(title)}</title>
          <description>#{xml_escape(feed_description(event))}</description>
          #{publication_date(captured_at)}
          <link>#{xml_escape(link)}</link>
          <guid isPermaLink="false">#{xml_escape(event_id)}</guid>
        </item>
    """
  end

  defp feed_description(event) do
    event
    |> map_get("changes", :changes)
    |> List.wrap()
    |> Enum.map(fn change ->
      operation = map_get(change, "op", :op) || "changed"
      path = map_get(change, "path", :path) || "model"
      "#{path} #{operation}"
    end)
    |> case do
      [] -> "Model record changed."
      changes -> Enum.join(changes, "; ")
    end
  end

  defp publication_date(value) do
    case parse_datetime(value) do
      {:ok, date_time} -> "<pubDate>#{rfc822(date_time)}</pubDate>"
      :error -> ""
    end
  end

  defp feed_last_build_date([first | _rest]) do
    case first |> map_get("captured_at", :captured_at) |> parse_datetime() do
      {:ok, date_time} -> "    <lastBuildDate>#{rfc822(date_time)}</lastBuildDate>\n"
      :error -> ""
    end
  end

  defp feed_last_build_date([]), do: ""

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, date_time, _offset} -> {:ok, date_time}
      _ -> :error
    end
  end

  defp parse_datetime(_value), do: :error

  defp rfc822(date_time) do
    date_time
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")
  end

  defp xml_escape(value) do
    value
    |> to_string()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp map_get(nil, _string_key, _atom_key), do: nil

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end
end
