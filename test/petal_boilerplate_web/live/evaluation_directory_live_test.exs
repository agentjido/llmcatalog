defmodule PetalBoilerplateWeb.EvaluationDirectoryLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog.ProviderDirectory
  alias PetalBoilerplateWeb.PublicRoutes

  test "evaluation page shows exact TypeSafe specs and model links", %{conn: conn} do
    html = conn |> get("/models/evaluation") |> html_response(200)

    assert html =~ "Evaluation Models"
    assert html =~ "typed decisions"
    assert html =~ "ReqLLM can call"
    assert html =~ "typesafe:jev-latest"
    assert html =~ "typesafe:jev-preview"
    assert html =~ "typesafe:jev-1.13.0"
    assert html =~ "openrouter:typesafe/jev-1.13"
    assert html =~ "openrouter:~typesafe/jev-latest"
    assert html =~ ~s(href="/models/typesafe/jev-latest")
    assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute("/models/evaluation")}")
    assert html =~ ~s(href="/models/evaluation.md")
  end

  test "Evaluate appears on detail and filter results", %{conn: conn} do
    detail = conn |> get("/models/typesafe/jev-latest") |> html_response(200)

    assert detail
           |> Floki.parse_document!()
           |> Floki.find("span")
           |> Enum.any?(&(Floki.text(&1) |> String.trim() == "Evaluate"))

    filtered = build_conn() |> get("/?caps=evaluate") |> html_response(200)
    assert filtered =~ "jev-latest"
    assert filtered =~ "Evaluate"
  end

  test "provider page lists all providers with working filtered links", %{conn: conn} do
    html = conn |> get("/providers") |> html_response(200)
    document = Floki.parse_document!(html)
    entries = ProviderDirectory.entries()

    assert html =~ "Model Provider Directory"
    assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute("/providers")}")

    assert length(Floki.find(document, ~s(section[aria-labelledby="providers-heading"] li))) ==
             length(entries)

    typesafe = Enum.find(entries, &(&1.id == "typesafe"))
    assert typesafe.model_count > 0
    assert typesafe.evaluation_count == 3

    path = ProviderDirectory.catalog_path("typesafe")
    assert path in (Floki.find(document, "a") |> Floki.attribute("href"))

    filtered = build_conn() |> get(path) |> html_response(200)
    assert filtered =~ "jev-latest"
  end

  test "new routes have Markdown and discovery links", %{conn: conn} do
    for route <- ["/models/evaluation", "/providers"] do
      markdown = conn |> recycle() |> get(route <> ".md") |> response(200)
      assert markdown =~ "Canonical URL: #{PublicRoutes.absolute(route)}"
    end

    sitemap = build_conn() |> get("/sitemap.xml") |> response(200)
    assert sitemap =~ PublicRoutes.absolute("/models/evaluation")
    assert sitemap =~ PublicRoutes.absolute("/providers")

    llms = build_conn() |> get("/llms.txt") |> response(200)
    assert llms =~ PublicRoutes.absolute("/models/evaluation")
    assert llms =~ PublicRoutes.absolute("/providers")
  end
end
