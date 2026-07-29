defmodule PetalBoilerplateWeb.SearchIndexingTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  setup do
    indexing = Application.get_env(:petal_boilerplate, :seo_indexing_enabled)

    on_exit(fn ->
      Application.put_env(:petal_boilerplate, :seo_indexing_enabled, indexing)
    end)

    :ok
  end

  test "disabled indexing adds headers, noindex metadata, and no canonical", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :seo_indexing_enabled, false)

    conn = get(conn, "/")
    html = html_response(conn, 200)

    assert get_resp_header(conn, "x-robots-tag") == ["noindex, nofollow"]
    assert html =~ ~s(name="robots" content="noindex, nofollow")
    refute html =~ ~s(rel="canonical")
  end

  test "disabled indexing preserves noimageindex on social images", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :seo_indexing_enabled, false)

    conn = get(conn, "/og/home.png")
    directives = get_resp_header(conn, "x-robots-tag") |> List.first()

    assert response(conn, 200)
    assert directives =~ "noindex"
    assert directives =~ "nofollow"
    assert directives =~ "noimageindex"
  end
end
