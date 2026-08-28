defmodule PetalBoilerplateWeb.MCPController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.APIProblem
  alias PetalBoilerplateWeb.MCP

  @jsonrpc "2.0"

  def handle(conn, %{"jsonrpc" => @jsonrpc} = request) do
    if Map.has_key?(request, "id") do
      handle_request(conn, request)
    else
      handle_notification(conn, request)
    end
  end

  # Compatibility for clients that used the former small tool interface.
  def handle(conn, %{"method" => "tools/list"}) do
    json(conn, %{tools: MCP.tools()})
  end

  def handle(conn, %{
        "method" => "tools/call",
        "params" => %{"name" => name} = params
      }) do
    case MCP.call_tool(name, Map.get(params, "arguments", %{})) do
      {:ok, result} -> json(conn, result)
      {:error, message} -> invalid_legacy_request(conn, message)
    end
  end

  def handle(conn, _params), do: invalid_legacy_request(conn, "Unsupported tool request.")

  defp handle_request(conn, %{"id" => id, "method" => "initialize"} = request) do
    result = MCP.initialize(Map.get(request, "params", %{}))
    jsonrpc_result(conn, id, result, result.protocolVersion)
  end

  defp handle_request(conn, %{"id" => id, "method" => "ping"}) do
    jsonrpc_result(conn, id, %{})
  end

  defp handle_request(conn, %{"id" => id, "method" => "tools/list"}) do
    jsonrpc_result(conn, id, %{tools: MCP.tools()})
  end

  defp handle_request(
         conn,
         %{"id" => id, "method" => "tools/call", "params" => %{"name" => name} = params}
       ) do
    case MCP.call_tool(name, Map.get(params, "arguments", %{})) do
      {:ok, result} -> jsonrpc_result(conn, id, result)
      {:error, message} -> jsonrpc_error(conn, id, -32602, message)
    end
  end

  defp handle_request(conn, %{"id" => id, "method" => "resources/list"}) do
    jsonrpc_result(conn, id, %{resources: MCP.resources()})
  end

  defp handle_request(
         conn,
         %{"id" => id, "method" => "resources/read", "params" => %{"uri" => uri}}
       ) do
    case MCP.read_resource(uri) do
      {:ok, result} -> jsonrpc_result(conn, id, result)
      {:error, :not_found} -> jsonrpc_error(conn, id, -32002, "Resource not found", %{uri: uri})
    end
  end

  defp handle_request(conn, %{"id" => id, "method" => "resources/templates/list"}) do
    jsonrpc_result(conn, id, %{resourceTemplates: []})
  end

  defp handle_request(conn, %{"id" => id}) do
    jsonrpc_error(conn, id, -32601, "Method not found")
  end

  defp handle_notification(conn, %{"method" => method})
       when method in ["notifications/initialized", "notifications/cancelled"] do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(202, "")
  end

  defp handle_notification(conn, _request) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(202, "")
  end

  defp jsonrpc_result(conn, id, result, protocol_version \\ nil) do
    conn
    |> maybe_put_protocol_version(protocol_version)
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_content_type("application/json", "utf-8")
    |> send_resp(200, Jason.encode!(%{jsonrpc: @jsonrpc, id: id, result: result}))
  end

  defp jsonrpc_error(conn, id, code, message, data \\ nil) do
    error = %{code: code, message: message}
    error = if is_nil(data), do: error, else: Map.put(error, :data, data)

    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_content_type("application/json", "utf-8")
    |> send_resp(200, Jason.encode!(%{jsonrpc: @jsonrpc, id: id, error: error}))
  end

  defp maybe_put_protocol_version(conn, nil), do: conn

  defp maybe_put_protocol_version(conn, protocol_version) do
    put_resp_header(conn, "mcp-protocol-version", protocol_version)
  end

  defp invalid_legacy_request(conn, detail) do
    APIProblem.respond(
      conn,
      :bad_request,
      "invalid_tool_request",
      detail,
      resolution:
        "Send a JSON-RPC 2.0 initialize request, then use tools/list or tools/call as documented on /developers."
    )
  end
end
