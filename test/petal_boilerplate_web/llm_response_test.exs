defmodule PetalBoilerplateWeb.LLMResponseTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LandingPages
  alias PetalBoilerplateWeb.PublicRoutes

  test "HTML pages advertise llms.txt and their Markdown copy", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200)

    link = get_resp_header(conn, "link") |> List.first()
    vary = get_resp_header(conn, "vary") |> List.first()

    assert link =~ ~s(</llms.txt>; rel="alternate"; type="text/plain")

    assert link =~
             "<#{PublicRoutes.absolute("/index.md")}>; rel=\"alternate\"; type=\"text/markdown\""

    assert link =~
             ~s(</openapi.json>; rel="service-desc"; type="application/vnd.oai.openapi+json;version=3.1")

    assert link =~ ~s(</developers>; rel="help"; type="text/html")
    assert link =~ ~s(</developers>; rel="service-doc"; type="text/html")
    assert link =~ ~s(</.well-known/ard.json>; rel="ard"; type="application/json")
    assert link =~ ~s(</.well-known/api-catalog>; rel="api-catalog")
    assert link =~ ~s(</.well-known/mcp.json>; rel="alternate"; type="application/json")
    assert link =~ ~s(</.well-known/mcp/server-card.json>; rel="service-desc")

    assert vary =~ "Accept"
  end

  test "Accept text/markdown returns model Markdown with SEO headers", %{conn: conn} do
    path = "/models/openai/gpt-4o"

    conn =
      conn
      |> put_req_header("accept", "text/markdown")
      |> get(path)

    body = response(conn, 200)
    link = get_resp_header(conn, "link") |> List.first()

    assert get_resp_header(conn, "content-type") |> hd() =~ "text/markdown"
    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
    assert link =~ "<#{PublicRoutes.absolute(path)}>; rel=\"canonical\""

    assert link =~
             "<#{PublicRoutes.absolute(path <> ".md")}>; rel=\"alternate\"; type=\"text/markdown\""

    assert body =~ "# GPT-4o"
    assert body =~ "Provider: openai"
    assert body =~ ~s(title: "GPT-4o")
    assert body =~ ~s(description: "Machine-readable Markdown for GPT-4o)
    assert body =~ ~s(canonical: "#{PublicRoutes.absolute(path)}")
    assert body =~ ~s(canonical_url: "#{PublicRoutes.absolute(path)}")
  end

  test "explicit Markdown routes return deterministic page equivalents", %{conn: conn} do
    for {path, expected} <- [
          {"/index.md", "# LLM Catalog by Jidoka Labs"},
          {"/llm-models.md", "# LLM Models List"},
          {"/about.md", "# About LLM Catalog"},
          {"/contact.md", "# Contact LLM Catalog"},
          {"/developers.md", "# LLM Catalog developer resources by Jidoka Labs"},
          {"/privacy.md", "# LLM Catalog by Jidoka Labs privacy policy"},
          {"/history.md", "# Recent LLM Model History"}
        ] do
      response_conn = get(conn, path)

      assert response(response_conn, 200) =~ expected
      assert get_resp_header(response_conn, "content-type") |> hd() =~ "text/markdown"
      assert get_resp_header(response_conn, "x-robots-tag") == ["noindex"]
    end

    assert get(conn, "/llm-models.md") |> response(200) =~ "## Limits of the data"
  end

  test "explicit Markdown supports model IDs with nested path segments", %{conn: conn} do
    model = Enum.find(Catalog.list_all_models(), &String.contains?(&1.model_id, "/"))
    path = PublicRoutes.model_markdown_path(model)

    response_conn = get(conn, path)

    assert response(response_conn, 200) =~ "Model ID: `#{model.model_id}`"
    assert get_resp_header(response_conn, "content-type") |> hd() =~ "text/markdown"
  end

  test "all catalog landing pages provide explicit Markdown copies", %{conn: conn} do
    for route <- LandingPages.routes() do
      response_conn = conn |> recycle() |> get(route <> ".md")
      body = response(response_conn, 200)

      assert get_resp_header(response_conn, "content-type") |> hd() =~ "text/markdown"
      assert get_resp_header(response_conn, "x-robots-tag") == ["noindex"]
      assert body =~ "## Sources"
      assert body =~ "## Related LLM model lists"
      assert body =~ "Canonical URL: #{PublicRoutes.absolute(route)}"
    end
  end

  test "query variants negotiate the base Markdown representation", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "text/markdown")
      |> get("/?q=gpt")

    link = get_resp_header(conn, "link") |> List.first()

    assert response(conn, 200) =~ "# LLM Catalog"
    assert link =~ "<#{PublicRoutes.absolute("/")}>; rel=\"canonical\""
    refute link =~ "?q=gpt"
  end

  test "invalid explicit model Markdown returns 404", %{conn: conn} do
    conn = get(conn, "/models/not-real/not-real.md")
    body = response(conn, 404)

    assert body =~ "Page not found"
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/markdown"
    assert get_resp_header(conn, "x-robots-tag") == ["noindex, nofollow"]
  end

  test "unknown pages negotiate a recovery-focused Markdown 404", %{conn: conn} do
    conn = conn |> put_req_header("accept", "text/markdown") |> get("/not-a-page")

    assert response(conn, 404) =~ "[Developer guide](/developers)"
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/markdown"
    assert get_resp_header(conn, "vary") == ["Accept"]
  end

  test "machine routes do not negotiate Markdown", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "text/markdown")
      |> get("/sitemap.xml")

    assert response(conn, 200) =~ "<urlset"
    assert get_resp_header(conn, "content-type") |> hd() =~ "application/xml"
    assert get_resp_header(conn, "link") == []
  end
end
