defmodule PetalBoilerplateWeb.MCPTransportTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  @modern_version "2026-07-28"
  @legacy_version "2025-11-25"

  test "discovers the current stateless server", %{conn: conn} do
    conn = modern_request(conn, 1, "server/discover")
    body = json_response(conn, 200)
    result = body["result"]

    assert body["jsonrpc"] == "2.0"
    assert body["id"] == 1
    assert hd(result["supportedVersions"]) == @modern_version
    assert @legacy_version in result["supportedVersions"]
    assert result["capabilities"]["tools"]["listChanged"] == false
    assert result["capabilities"]["resources"]["subscribe"] == false
    assert result["cacheScope"] == "public"
    assert result["ttlMs"] > 0

    assert result["_meta"]["io.modelcontextprotocol/serverInfo"]["name"] ==
             "io.github.agentjido/llmcatalog"

    assert get_resp_header(conn, "mcp-protocol-version") == [@modern_version]
    assert get_resp_header(conn, "mcp-session-id") == []
  end

  test "lists and calls the public read-only tools", %{conn: conn} do
    list = conn |> modern_request(2, "tools/list") |> json_response(200)
    tools = list["result"]["tools"]

    assert MapSet.new(Enum.map(tools, & &1["name"])) ==
             MapSet.new(["query_models", "get_model", "list_providers"])

    assert Enum.all?(tools, & &1["annotations"]["readOnlyHint"])
    assert Enum.all?(tools, &(not &1["annotations"]["destructiveHint"]))
    assert Enum.all?(tools, &(&1["inputSchema"]["additionalProperties"] == false))

    call =
      build_conn()
      |> modern_request(3, "tools/call", %{
        "name" => "get_model",
        "arguments" => %{"spec" => "openai:gpt-4o"}
      })
      |> json_response(200)

    assert call["result"]["isError"] == false
    assert call["result"]["structuredContent"]["model"]["spec"] == "openai:gpt-4o"
    assert [%{"type" => "text", "text" => text}] = call["result"]["content"]
    assert Jason.decode!(text)["model"]["spec"] == "openai:gpt-4o"

    query =
      build_conn()
      |> modern_request(4, "tools/call", %{
        "name" => "query_models",
        "arguments" => %{"provider" => "openai", "limit" => 2}
      })
      |> json_response(200)

    assert query["result"]["structuredContent"]["count"] <= 2

    assert Enum.all?(
             query["result"]["structuredContent"]["models"],
             &(&1["provider"] == "openai")
           )

    providers =
      build_conn()
      |> modern_request(16, "tools/call", %{"name" => "list_providers", "arguments" => %{}})
      |> json_response(200)

    assert providers["result"]["isError"] == false

    assert [%{"id" => _, "model_count" => count} | _rest] =
             providers["result"]["structuredContent"]["providers"]

    assert count >= 0
  end

  test "returns actionable tool errors for every invalid input shape", %{conn: conn} do
    invalid_query =
      conn
      |> modern_request(5, "tools/call", %{
        "name" => "query_models",
        "arguments" => %{"limit" => 0, "extra" => true}
      })
      |> json_response(200)

    assert invalid_query["result"]["isError"]
    assert invalid_query["result"]["content"] |> hd() |> Map.fetch!("text") =~ "Invalid arguments"
    refute invalid_query["result"]["structuredContent"]

    invalid_spec =
      build_conn()
      |> modern_request(6, "tools/call", %{
        "name" => "get_model",
        "arguments" => %{"spec" => "not-a-spec"}
      })
      |> json_response(200)

    assert invalid_spec["result"]["isError"]

    invalid_provider_args =
      build_conn()
      |> modern_request(7, "tools/call", %{
        "name" => "list_providers",
        "arguments" => %{"unexpected" => true}
      })
      |> json_response(200)

    assert invalid_provider_args["result"]["isError"]

    unknown_tool =
      build_conn()
      |> modern_request(8, "tools/call", %{"name" => "missing", "arguments" => %{}})
      |> json_response(200)

    assert unknown_tool["error"]["code"] == -32602
    assert unknown_tool["error"]["message"] == "Unknown tool: missing"
  end

  test "lists and reads public resources without nested result wrappers", %{conn: conn} do
    list = conn |> modern_request(9, "resources/list") |> json_response(200)
    uris = Enum.map(list["result"]["resources"], & &1["uri"])

    assert "llmcatalog://overview" in uris
    assert "llmcatalog://openapi" in uris
    assert "llmcatalog://providers" in uris

    read =
      build_conn()
      |> modern_request(10, "resources/read", %{"uri" => "llmcatalog://overview"})
      |> json_response(200)

    assert [%{"mimeType" => "text/markdown", "text" => text}] = read["result"]["contents"]
    assert text =~ "LLM Catalog by Jidoka Labs"
    refute hd(read["result"]["contents"])["contents"]
  end

  test "rejects invalid origins, metadata, protocol versions, and large bodies", %{conn: conn} do
    invalid_origin =
      conn
      |> put_req_header("origin", "https://untrusted.example")
      |> modern_request(11, "server/discover")

    assert response(invalid_origin, 403)

    mismatched_method =
      build_conn()
      |> modern_request(12, "tools/list", %{}, method_header: "resources/list")

    assert json_response(mismatched_method, 400)["error"]["code"] == -32020

    unsupported =
      build_conn()
      |> modern_request(13, "server/discover", %{}, protocol_version: "2099-01-01")

    unsupported_body = json_response(unsupported, 400)
    assert unsupported_body["error"]["code"] == -32022
    assert unsupported_body["error"]["data"]["requested"] == "2099-01-01"

    oversized =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> put_req_header("mcp-protocol-version", @modern_version)
      |> put_req_header("mcp-method", "tools/list")
      |> post("/api/mcp", String.duplicate("x", 256_001))

    assert response(oversized, 413)
  end

  test "supports an initialization-based legacy client", %{conn: conn} do
    initialize =
      conn
      |> post_json(%{
        "jsonrpc" => "2.0",
        "id" => 14,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => @legacy_version,
          "capabilities" => %{},
          "clientInfo" => %{"name" => "legacy-test", "version" => "1.0"}
        }
      })

    initialize_body = json_response(initialize, 200)
    assert initialize_body["result"]["protocolVersion"] == @legacy_version
    assert initialize_body["result"]["serverInfo"]["name"] == "io.github.agentjido/llmcatalog"
    assert [session_id] = get_resp_header(initialize, "mcp-session-id")

    list =
      build_conn()
      |> put_req_header("mcp-protocol-version", @legacy_version)
      |> put_req_header("mcp-session-id", session_id)
      |> post_json(%{"jsonrpc" => "2.0", "id" => 15, "method" => "tools/list", "params" => %{}})
      |> json_response(200)

    assert length(list["result"]["tools"]) == 3
  end

  defp modern_request(conn, id, method, params \\ %{}, opts \\ []) do
    protocol_version = Keyword.get(opts, :protocol_version, @modern_version)
    method_header = Keyword.get(opts, :method_header, method)

    meta = %{
      "io.modelcontextprotocol/protocolVersion" => protocol_version,
      "io.modelcontextprotocol/clientCapabilities" => %{},
      "io.modelcontextprotocol/clientInfo" => %{"name" => "llmcatalog-test", "version" => "1.0"}
    }

    params = Map.put(params, "_meta", meta)

    conn =
      conn
      |> put_req_header("mcp-protocol-version", protocol_version)
      |> put_req_header("mcp-method", method_header)
      |> put_name_header(method, params)

    post_json(conn, %{"jsonrpc" => "2.0", "id" => id, "method" => method, "params" => params})
  end

  defp put_name_header(conn, "tools/call", params),
    do: put_req_header(conn, "mcp-name", params["name"])

  defp put_name_header(conn, "resources/read", params),
    do: put_req_header(conn, "mcp-name", params["uri"])

  defp put_name_header(conn, _method, _params), do: conn

  defp post_json(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json, text/event-stream")
    |> post("/api/mcp", Jason.encode!(payload))
  end
end
