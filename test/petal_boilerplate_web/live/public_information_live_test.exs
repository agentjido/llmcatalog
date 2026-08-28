defmodule PetalBoilerplateWeb.PublicInformationLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "developer guide documents supported interfaces and package limits", %{conn: conn} do
    html = conn |> get("/developers") |> html_response(200)

    assert html =~ "LLM Catalog by Jidoka Labs"
    assert html =~ "OpenAPI 3.1 document"
    assert html =~ "@agentjido/llmdb"
    assert html =~ "does not currently install a command-line executable"
    assert html =~ "stateless MCP Streamable HTTP server"
    assert html =~ "Versioning and deprecation"
    assert html =~ "RateLimit-Policy"
    assert html =~ "application/problem+json"
    assert html =~ ~s(rel="canonical" href="#{PetalBoilerplateWeb.Endpoint.url()}/developers")
  end

  test "contact page gives public and private support routes", %{conn: conn} do
    html = conn |> get("/contact") |> html_response(200)

    assert html =~ "Contact LLM Catalog"
    assert html =~ "Incorrect model data"
    assert html =~ "github.com/agentjido/llmcatalog/issues"
    assert html =~ "https://jidokahq.com/#contact"
    assert html =~ "no paid support plan"
  end

  test "privacy policy states current analytics behavior", %{conn: conn} do
    html = conn |> get("/privacy") |> html_response(200)

    assert html =~ "Effective August 25, 2026"
    assert html =~ "Plausible Analytics"
    assert html =~ "exact catalog allowlist"
    assert html =~ ~s(recorded only as "other")
    refute html =~ "PostHog"
    assert html =~ "do not sell personal data"
    assert html =~ ~s(rel="canonical" href="#{PetalBoilerplateWeb.Endpoint.url()}/privacy")
  end
end
