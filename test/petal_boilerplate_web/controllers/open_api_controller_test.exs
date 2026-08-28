defmodule PetalBoilerplateWeb.OpenAPIControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "GET /openapi.json returns a public OpenAPI document", %{conn: conn} do
    conn = get(conn, "/openapi.json")
    document = json_response(conn, 200)

    assert document["openapi"] == "3.1.0"
    assert document["info"]["title"] == "LLM Catalog by Jidoka Labs API"

    assert document["paths"]["/api/v1/history/recent"]["get"]["operationId"] ==
             "listRecentModelHistory"

    assert document["paths"]["/api/v1/history/{provider}/{model_id}"]["get"]["operationId"] ==
             "getModelHistory"

    assert document["paths"]["/api/history/recent"]["get"]["deprecated"]
    assert document["x-api-versioning"]["current"] == "v1"
    assert document["paths"]["/api/mcp"]["post"]["operationId"] == "sendMCPMessage"
    assert document["paths"]["/api/mcp"]["post"]["responses"]["429"]
    assert "resolution" in document["components"]["schemas"]["Problem"]["required"]

    assert get_resp_header(conn, "content-type") |> hd() =~
             "application/vnd.oai.openapi+json"

    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
  end

  test "versioned routes publish quota fields and old routes publish deprecation fields", %{
    conn: conn
  } do
    versioned = get(conn, "/api/v1/history/recent?limit=1")

    assert get_resp_header(versioned, "api-version") == ["1"]
    assert get_resp_header(versioned, "ratelimit-policy") != []
    assert get_resp_header(versioned, "ratelimit") != []
    assert get_resp_header(versioned, "deprecation") == []

    legacy = build_conn() |> get("/api/history/recent?limit=1")

    assert get_resp_header(legacy, "deprecation") == ["@1787875200"]
    assert get_resp_header(legacy, "link") |> hd() =~ ~s(rel="successor-version")
    assert get_resp_header(legacy, "link") |> hd() =~ "/api/v1/history/recent"
  end

  test "unknown API routes and wrong methods return problem JSON", %{conn: conn} do
    unknown = get(conn, "/api/not-real")
    unknown_body = json_response(unknown, 404)

    assert unknown_body["code"] == "api_route_not_found"
    assert unknown_body["status"] == 404
    assert unknown_body["resolution"] =~ "/openapi.json"
    assert get_resp_header(unknown, "content-type") |> hd() =~ "application/problem+json"

    wrong_method = build_conn() |> get("/api/mcp")
    assert response(wrong_method, 405)
    assert get_resp_header(wrong_method, "allow") == ["POST"]

    invalid_tool =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/api/mcp", Jason.encode!(%{"method" => "not-supported"}))

    invalid_tool_body = json_response(invalid_tool, 400)

    assert invalid_tool_body["error"]["code"] == -32600
    assert get_resp_header(invalid_tool, "content-type") |> hd() =~ "application/json"
  end
end
