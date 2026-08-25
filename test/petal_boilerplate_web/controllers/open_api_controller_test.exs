defmodule PetalBoilerplateWeb.OpenAPIControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "GET /openapi.json returns a public OpenAPI document", %{conn: conn} do
    conn = get(conn, "/openapi.json")
    document = json_response(conn, 200)

    assert document["openapi"] == "3.1.0"
    assert document["info"]["title"] == "LLM Catalog by Jidoka Labs API"

    assert document["paths"]["/api/history/recent"]["get"]["operationId"] ==
             "listRecentModelHistory"

    assert document["paths"]["/api/history/{provider}/{model_id}"]["get"]["operationId"] ==
             "getModelHistory"

    assert document["paths"]["/api/mcp"]["post"]["operationId"] == "invokeCatalogTool"
    assert "resolution" in document["components"]["schemas"]["Problem"]["required"]
    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
  end

  test "unknown API routes and wrong methods return problem JSON", %{conn: conn} do
    unknown = get(conn, "/api/not-real")
    unknown_body = json_response(unknown, 404)

    assert unknown_body["code"] == "api_route_not_found"
    assert unknown_body["status"] == 404
    assert unknown_body["resolution"] =~ "/openapi.json"
    assert get_resp_header(unknown, "content-type") |> hd() =~ "application/problem+json"

    wrong_method = build_conn() |> get("/api/mcp")
    wrong_method_body = json_response(wrong_method, 405)

    assert wrong_method_body["code"] == "method_not_allowed"
    assert get_resp_header(wrong_method, "allow") == ["POST"]

    invalid_tool = build_conn() |> post("/api/mcp", %{"method" => "not-supported"})
    invalid_tool_body = json_response(invalid_tool, 400)

    assert invalid_tool_body["code"] == "invalid_tool_request"
    assert get_resp_header(invalid_tool, "content-type") |> hd() =~ "application/problem+json"
  end
end
