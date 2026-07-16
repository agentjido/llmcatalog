defmodule PetalBoilerplateWeb.AboutLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  test "about page reports live catalog counts and shares the global search", %{conn: conn} do
    {:ok, view, html} = live(conn, "/about")

    expected_counts =
      "#{Catalog.format_number(Catalog.total_model_count())} models across #{length(Catalog.list_providers())} providers"

    assert html =~ expected_counts

    render_change(view, "filter", %{"search" => "gpt 4"})
    assert_redirect(view, "/?q=gpt+4")
  end
end
