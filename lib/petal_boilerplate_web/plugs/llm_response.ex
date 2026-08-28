defmodule PetalBoilerplateWeb.Plugs.LLMResponse do
  @moduledoc """
  Adds LLM discovery headers and serves public pages as Markdown.
  """

  import Plug.Conn

  alias PetalBoilerplateWeb.MarkdownContent
  alias PetalBoilerplateWeb.PublicRoutes

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{method: method, request_path: request_path} = conn, _opts)
      when method in ["GET", "HEAD"] do
    case resolve_request_path(conn, request_path) do
      {canonical_path, markdown_path, explicit_markdown?} ->
        handle_match(conn, canonical_path, markdown_path, explicit_markdown?)

      :no_match ->
        conn
    end
  end

  def call(conn, _opts), do: conn

  defp resolve_request_path(_conn, "/index.md"), do: {"/", "/index.md", true}

  defp resolve_request_path(conn, request_path) do
    cond do
      exact_html_model?(request_path) and not markdown_requested?(conn) ->
        {request_path, PublicRoutes.markdown_path(request_path), false}

      String.ends_with?(request_path, ".md") ->
        canonical_path = String.trim_trailing(request_path, ".md")

        if MarkdownContent.eligible_public_path?(canonical_path) do
          {canonical_path, request_path, true}
        else
          :no_match
        end

      MarkdownContent.eligible_public_path?(request_path) ->
        {request_path, PublicRoutes.markdown_path(request_path), false}

      true ->
        :no_match
    end
  end

  defp handle_match(conn, canonical_path, markdown_path, explicit_markdown?) do
    canonical_url = PublicRoutes.absolute(canonical_path)
    markdown_url = PublicRoutes.absolute(markdown_path)

    if explicit_markdown? or markdown_requested?(conn) do
      case MarkdownContent.resolve(canonical_path, canonical_url) do
        {:ok, markdown} ->
          conn
          |> put_discovery_headers(markdown_url)
          |> put_resp_header("x-robots-tag", "noindex")
          |> add_link_entries(["<#{canonical_url}>; rel=\"canonical\""])
          |> put_resp_content_type("text/markdown", "utf-8")
          |> send_resp(200, add_frontmatter(markdown, canonical_url))
          |> halt()

        :no_match ->
          conn
      end
    else
      register_before_send(conn, fn conn ->
        put_discovery_headers(conn, markdown_url)
      end)
    end
  end

  defp put_discovery_headers(conn, markdown_url) do
    conn
    |> put_vary_accept()
    |> add_link_entries([
      "</llms.txt>; rel=\"alternate\"; type=\"text/plain\"",
      "<#{markdown_url}>; rel=\"alternate\"; type=\"text/markdown\"",
      "</openapi.json>; rel=\"service-desc\"; type=\"application/vnd.oai.openapi+json;version=3.1\"",
      "</developers>; rel=\"help\"; type=\"text/html\"",
      "</developers>; rel=\"service-doc\"; type=\"text/html\"",
      "</.well-known/ard.json>; rel=\"ard\"; type=\"application/json\"",
      "</.well-known/ai-catalog.json>; rel=\"ai-catalog\"; type=\"application/json\"",
      "</.well-known/api-catalog>; rel=\"api-catalog\"; type=\"application/linkset+json\"",
      "</.well-known/mcp.json>; rel=\"alternate\"; type=\"application/json\"",
      "</.well-known/mcp/server-card.json>; rel=\"service-desc\"; type=\"application/mcp-server-card+json\""
    ])
  end

  defp put_vary_accept(conn) do
    values =
      conn
      |> get_resp_header("vary")
      |> Enum.flat_map(&parse_comma_separated/1)

    values =
      if Enum.any?(values, &(String.downcase(&1) == "accept")) do
        values
      else
        values ++ ["Accept"]
      end

    put_resp_header(conn, "vary", Enum.join(values, ", "))
  end

  defp add_link_entries(conn, entries) do
    existing =
      conn
      |> get_resp_header("link")
      |> Enum.flat_map(&parse_comma_separated/1)

    put_resp_header(conn, "link", Enum.join(Enum.uniq(existing ++ entries), ", "))
  end

  defp parse_comma_separated(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp add_frontmatter(markdown, canonical_url) do
    title =
      case Regex.run(~r/^#\s+(.+)$/m, markdown, capture: :all_but_first) do
        [heading] -> String.trim(heading)
        _match -> "LLM Catalog by Jidoka Labs"
      end

    """
    ---
    title: #{Jason.encode!(title)}
    description: #{Jason.encode!("Machine-readable Markdown for #{title} from LLM Catalog by Jidoka Labs.")}
    canonical: #{Jason.encode!(canonical_url)}
    canonical_url: #{Jason.encode!(canonical_url)}
    source: "LLM Catalog by Jidoka Labs"
    ---

    #{String.trim_leading(markdown)}
    """
  end

  defp exact_html_model?(path), do: match?({:ok, _model}, PublicRoutes.model_from_path(path))

  defp markdown_requested?(conn) do
    conn
    |> get_req_header("accept")
    |> Enum.any?(&String.contains?(String.downcase(&1), "text/markdown"))
  end
end
