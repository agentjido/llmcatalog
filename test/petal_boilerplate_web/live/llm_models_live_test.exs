defmodule PetalBoilerplateWeb.LLMModelsLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LLMModelsList
  alias PetalBoilerplateWeb.LandingLinks
  alias PetalBoilerplateWeb.PublicRoutes

  test "renders one useful indexable LLM models list page", %{conn: conn} do
    snapshot = LLMModelsList.snapshot()

    html =
      conn
      |> get("/llm-models")
      |> html_response(200)

    assert heading_texts(html, "h1") == ["LLM Models List"]
    assert html =~ "Active LLM model IDs"
    assert html =~ "How this LLM list works"
    assert html =~ "does not rank model quality"
    assert html =~ "What this page can answer"
    assert html =~ "models.dev"
    assert html =~ "Use the data"
    assert html =~ "Related LLM model lists"
    assert html =~ Catalog.format_number(snapshot.model_identity_count)
    assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute("/llm-models")}")
    refute html =~ ~s(name="robots" content="noindex)

    pack_routes =
      html
      |> Floki.parse_document!()
      |> Floki.find("#related-model-lists a")
      |> Floki.attribute("href")

    assert pack_routes ==
             "/llm-models" |> LandingLinks.links_for() |> Enum.map(& &1.route)
  end

  test "paginates the model identities and noindexes query variants", %{conn: conn} do
    html =
      conn
      |> get("/llm-models?page=2")
      |> html_response(200)

    assert html =~ "Page 2 of"
    assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute("/llm-models")}")
    assert html =~ ~s(name="robots" content="noindex, follow")
  end

  test "supports LiveView rendering and search handoff to the catalog", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/llm-models")

    assert has_element?(view, "table tbody tr")
    assert has_element?(view, ~s(a[href="/llm-models.md"]))

    view
    |> form("#model-search-form", %{"search" => "gpt-4o"})
    |> render_change()

    assert_redirect(view, "/?q=gpt-4o")
  end

  defp heading_texts(html, selector) do
    html
    |> Floki.parse_document!()
    |> Floki.find(selector)
    |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
  end
end
