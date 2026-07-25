defmodule PetalBoilerplateWeb.LLMResponseTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.PublicRoutes

  test "HTML pages advertise llms.txt and their Markdown copy", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200)

    link = get_resp_header(conn, "link") |> List.first()
    vary = get_resp_header(conn, "vary") |> List.first()

    assert link =~ ~s(</llms.txt>; rel="alternate"; type="text/plain")

    assert link =~
             "<#{PublicRoutes.absolute("/index.md")}>; rel=\"alternate\"; type=\"text/markdown\""

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
  end

  test "explicit Markdown routes return deterministic page equivalents", %{conn: conn} do
    for {path, expected} <- [
          {"/index.md", "# LLM Model Database"},
          {"/about.md", "# About llmdb.xyz"},
          {"/history.md", "# Recent LLM Model History"}
        ] do
      response_conn = get(conn, path)

      assert response(response_conn, 200) =~ expected
      assert get_resp_header(response_conn, "content-type") |> hd() =~ "text/markdown"
      assert get_resp_header(response_conn, "x-robots-tag") == ["noindex"]
    end
  end

  test "explicit Markdown supports model IDs with nested path segments", %{conn: conn} do
    model = Enum.find(Catalog.list_all_models(), &String.contains?(&1.model_id, "/"))
    path = PublicRoutes.model_markdown_path(model)

    response_conn = get(conn, path)

    assert response(response_conn, 200) =~ "Model ID: `#{model.model_id}`"
    assert get_resp_header(response_conn, "content-type") |> hd() =~ "text/markdown"
  end

  test "query variants negotiate the base Markdown representation", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "text/markdown")
      |> get("/?q=gpt")

    link = get_resp_header(conn, "link") |> List.first()

    assert response(conn, 200) =~ "# LLM Model Database"
    assert link =~ "<#{PublicRoutes.absolute("/")}>; rel=\"canonical\""
    refute link =~ "?q=gpt"
  end

  test "invalid explicit model Markdown returns 404", %{conn: conn} do
    conn = get(conn, "/models/not-real/not-real.md")
    body = html_response(conn, 404)

    assert body =~ "Page not found"
    assert get_resp_header(conn, "x-robots-tag") == ["noindex, nofollow"]
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
