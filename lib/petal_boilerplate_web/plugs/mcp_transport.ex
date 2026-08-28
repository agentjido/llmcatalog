defmodule PetalBoilerplateWeb.Plugs.MCPTransport do
  @moduledoc """
  Serves the public MCP endpoint before the general request-body parsers.

  ExMCP owns JSON-RPC validation, dual-era protocol negotiation, bounded body
  parsing, HTTP transport security, and response framing. The catalog owns only
  its read-only tools and resources.
  """

  @behaviour Plug

  import Plug.Conn

  alias PetalBoilerplateWeb.MCP
  alias PetalBoilerplateWeb.MCPHandler
  alias PetalBoilerplateWeb.APIProblem
  alias PetalBoilerplateWeb.Plugs.RateLimit

  @endpoint_path "/api/mcp"

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{request_path: @endpoint_path} = conn, _opts) do
    conn = RateLimit.call(conn, RateLimit.init([]))

    if conn.halted do
      conn
    else
      dispatch(conn)
    end
  end

  def call(conn, _opts), do: conn

  defp dispatch(%Plug.Conn{method: "POST"} = conn) do
    conn
    |> ExMCP.HttpPlug.call(http_options())
    |> halt()
  end

  defp dispatch(conn) do
    conn
    |> put_resp_header("allow", "POST")
    |> APIProblem.respond(
      :method_not_allowed,
      "method_not_allowed",
      "The MCP endpoint accepts POST requests only.",
      resolution: "Send an MCP JSON-RPC request with HTTP POST."
    )
    |> halt()
  end

  defp http_options do
    transport_config = Application.get_env(:petal_boilerplate, :mcp_transport, [])

    [
      handler: MCPHandler,
      handler_call_timeout: 5_000,
      protocol_mode: :prefer_modern,
      path: @endpoint_path,
      body_limit: 256_000,
      validate_origin: true,
      allowed_hosts: Keyword.fetch!(transport_config, :allowed_hosts),
      allowed_origins: Keyword.fetch!(transport_config, :allowed_origins),
      server_info: MCP.server_info(),
      server_capabilities: MCP.capabilities(),
      instructions: MCP.instructions()
    ]
    |> ExMCP.HttpPlug.init()
  end
end
