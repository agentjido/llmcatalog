defmodule PetalBoilerplateWeb.ModelLiveSelectionTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

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
  end
end
