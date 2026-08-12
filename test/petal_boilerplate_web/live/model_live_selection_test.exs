defmodule PetalBoilerplateWeb.ModelLiveSelectionTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.PublicRoutes

  test "selected models render in the comparison modal via direct lookup ids", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")

    [first_model, second_model | _] =
      Catalog.query_models(Catalog.default_filters(), Catalog.default_sort(), 1)
      |> elem(0)

    assert html =~ ~s(phx-click="toggle_select")
    assert html =~ ~s(aria-label="Select #{first_model.name} for comparison")

    assert render_click(view, "toggle_select", %{"id" => first_model.id}) =~ "1"
    assert render_click(view, "toggle_select", %{"id" => second_model.id}) =~ "2"

    html = render_click(view, "open_comparison", %{})

    assert html =~ first_model.name
    assert html =~ second_model.name
    assert html =~ first_model.model_id
    assert html =~ second_model.model_id
    assert html =~ ~s(id="comparison-dialog")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")

    html = render_click(view, "close_comparison", %{})
    assert element_count(html, "#models-table-body tr") == 50
    assert element_count(html, ~s([id^="mobile-model-"])) == 50
  end

  test "model details render as a labelled modal dialog", %{conn: conn} do
    [model | _] =
      Catalog.query_models(Catalog.default_filters(), Catalog.default_sort(), 1)
      |> elem(0)

    {:ok, view, _html} = live(conn, "/")
    assert page_title(view) =~ "LLM Catalog"
    html = render_click(view, "show_model", %{"id" => model.id})
    canonical_url = PublicRoutes.absolute(PublicRoutes.model_path(model))

    assert html =~ ~s(id="model-detail-dialog")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(aria-labelledby="model-detail-title")
    assert html =~ ~s(aria-label="Close model details")
    assert html =~ ~s(<h1 id="model-detail-title")
    assert html =~ ~s(phx-hook="PageMetadata")
    assert html =~ ~s(data-indexing-enabled="true")
    assert html =~ ~s(data-canonical-url="#{canonical_url}")
    assert html =~ ~s(data-robots="noindex, follow")
    refute page_title(view) =~ "LLM Catalog"

    render_click(view, "close_model", %{})

    assert_patch(view, "/")
    assert page_title(view) == "LLM Catalog"
    refute has_element?(view, "#model-detail-dialog")
    assert has_element?(view, "##{model.id}")
    assert has_element?(view, "#catalog-heading")

    assert has_element?(
             view,
             ~s(#live-seo-metadata[data-canonical-url="#{PublicRoutes.absolute("/")}"])
           )

    refute has_element?(view, "#live-seo-metadata[data-robots]")
  end

  test "filtered catalog metadata is noindex with the home canonical", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/?q=gpt")

    assert has_element?(
             view,
             ~s(#live-seo-metadata[data-canonical-url="#{PublicRoutes.absolute("/")}"])
           )

    assert has_element?(view, ~s(#live-seo-metadata[data-robots="noindex, follow"]))
  end

  defp element_count(html, selector) do
    html
    |> Floki.parse_document!()
    |> Floki.find(selector)
    |> length()
  end
end
