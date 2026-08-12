defmodule PetalBoilerplateWeb.Plugs.CanonicalHost do
  @moduledoc """
  Redirects requests to the configured canonical host.

  Legacy LLMDB hosts continue to serve MCP POST requests so existing clients
  do not have to follow an HTTP redirect.
  """

  @behaviour Plug

  import Plug.Conn

  @mcp_path "/api/mcp"
  @permanent_redirect 308

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    canonical_host =
      Keyword.get_lazy(opts, :canonical_host, fn ->
        Application.get_env(:petal_boilerplate, :canonical_host)
      end)

    legacy_hosts =
      Keyword.get_lazy(opts, :legacy_hosts, fn ->
        Application.get_env(:petal_boilerplate, :legacy_hosts, [])
      end)
      |> List.wrap()

    cond do
      not configured?(canonical_host) -> conn
      conn.host == canonical_host -> conn
      legacy_mcp_request?(conn, legacy_hosts) -> conn
      true -> redirect(conn, canonical_host)
    end
  end

  defp configured?(host), do: is_binary(host) and host != ""

  defp legacy_mcp_request?(conn, legacy_hosts) do
    conn.method == "POST" and conn.request_path == @mcp_path and conn.host in legacy_hosts
  end

  defp redirect(conn, canonical_host) do
    location = redirect_location(conn, canonical_host)

    conn
    |> put_resp_header("location", location)
    |> put_resp_content_type("text/plain")
    |> send_resp(@permanent_redirect, "Permanent Redirect")
    |> halt()
  end

  defp redirect_location(conn, canonical_host) do
    query = if conn.query_string == "", do: "", else: "?#{conn.query_string}"
    "https://#{canonical_host}#{conn.request_path}#{query}"
  end
end
