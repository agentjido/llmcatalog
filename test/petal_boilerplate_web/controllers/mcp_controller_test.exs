defmodule PetalBoilerplateWeb.MCPControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "initializes an MCP client with tools and resources", %{conn: conn} do
    conn =
      post(conn, "/api/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-11-25",
          "capabilities" => %{},
          "clientInfo" => %{"name" => "test", "version" => "1.0"}
        }
      })

    body = json_response(conn, 200)
    result = body["result"]

    assert body["jsonrpc"] == "2.0"
    assert body["id"] == 1
    assert result["protocolVersion"] == "2025-11-25"
    assert result["serverInfo"]["name"] == "io.github.agentjido.llmcatalog"
    assert result["capabilities"]["tools"]["listChanged"] == false
    assert result["capabilities"]["resources"]["subscribe"] == false
    assert get_resp_header(conn, "mcp-protocol-version") == ["2025-11-25"]
  end

  test "lists and calls the public read-only tools", %{conn: conn} do
    list =
      conn
      |> post("/api/mcp", %{"jsonrpc" => "2.0", "id" => 2, "method" => "tools/list"})
      |> json_response(200)

    tools = list["result"]["tools"]

    assert Enum.map(tools, & &1["name"]) == ["query_models", "get_model", "list_providers"]
    assert Enum.all?(tools, & &1["annotations"]["readOnlyHint"])
    assert Enum.all?(tools, &(not &1["annotations"]["destructiveHint"]))

    call =
      build_conn()
      |> post("/api/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 3,
        "method" => "tools/call",
        "params" => %{"name" => "get_model", "arguments" => %{"spec" => "openai:gpt-4o"}}
      })
      |> json_response(200)

    assert call["result"]["isError"] == false
    assert call["result"]["structuredContent"]["model"]["spec"] == "openai:gpt-4o"
  end

  test "lists and reads public resources", %{conn: conn} do
    list =
      conn
      |> post("/api/mcp", %{"jsonrpc" => "2.0", "id" => 4, "method" => "resources/list"})
      |> json_response(200)

    uris = Enum.map(list["result"]["resources"], & &1["uri"])
    assert "llmcatalog://overview" in uris
    assert "llmcatalog://openapi" in uris
    assert "llmcatalog://providers" in uris

    read =
      build_conn()
      |> post("/api/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 5,
        "method" => "resources/read",
        "params" => %{"uri" => "llmcatalog://overview"}
      })
      |> json_response(200)

    [content] = read["result"]["contents"]
    assert content["mimeType"] == "text/markdown"
    assert content["text"] =~ "LLM Catalog by Jidoka Labs"
  end

  test "returns JSON-RPC errors and accepts notifications", %{conn: conn} do
    unknown =
      conn
      |> post("/api/mcp", %{"jsonrpc" => "2.0", "id" => "bad", "method" => "unknown"})
      |> json_response(200)

    assert unknown["id"] == "bad"
    assert unknown["error"]["code"] == -32601

    notification =
      build_conn()
      |> post("/api/mcp", %{"jsonrpc" => "2.0", "method" => "notifications/initialized"})

    assert response(notification, 202) == ""
  end
end
