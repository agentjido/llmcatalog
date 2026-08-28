defmodule PetalBoilerplateWeb.MCPHandler do
  @moduledoc """
  Connects the LLM Catalog tools and resources to the ExMCP protocol server.
  """

  use ExMCP.Server.Handler

  alias PetalBoilerplateWeb.MCP

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_initialize(params, state) do
    {:ok, MCP.initialize(params), state}
  end

  @impl true
  def handle_list_tools(_cursor, state) do
    {:ok, MCP.tools(), nil, state}
  end

  @impl true
  def handle_call_tool(name, arguments, state) do
    # ExMCP makes request metadata available to handlers through the argument
    # map. It is transport metadata, not part of the public tool input schema.
    case MCP.call_tool(name, Map.delete(arguments, "_meta")) do
      {:ok, result} ->
        {:ok, result, state}

      {:error, message} ->
        {:error, ExMCP.Error.protocol_error(-32602, message), state}
    end
  end

  @impl true
  def handle_list_resources(_cursor, state) do
    {:ok, MCP.resources(), nil, state}
  end

  @impl true
  def handle_read_resource(uri, state) do
    case MCP.read_resource(uri) do
      {:ok, %{contents: contents}} ->
        {:ok, contents, state}

      {:error, :not_found} ->
        {:error, ExMCP.Error.protocol_error(-32002, "Unknown resource: #{uri}"), state}
    end
  end
end
