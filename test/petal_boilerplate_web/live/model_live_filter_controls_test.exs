defmodule PetalBoilerplateWeb.ModelLiveFilterControlsTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  test "clear search preserves active filters", %{conn: conn} do
    provider_id = first_provider_id()

    {:ok, view, _html} = live(conn, "/?q=gpt&providers=#{provider_id}")

    assert has_element?(view, ~s(button[aria-label="Clear search"]))

    render_click(view, "clear_search", %{})

    assert_patch(view, "/?providers=#{provider_id}")
    refute has_element?(view, ~s(button[aria-label="Clear search"]))
    assert has_element?(view, "button", "Clear filters")
  end

  test "clear filters preserves search", %{conn: conn} do
    provider_id = first_provider_id()

    {:ok, view, _html} = live(conn, "/?q=gpt&providers=#{provider_id}&caps=tools")

    assert has_element?(view, "button", "Clear filters")

    render_click(view, "clear_filters", %{})

    assert_patch(view, "/?q=gpt")
    assert has_element?(view, ~s(button[aria-label="Clear search"]))
    refute has_element?(view, "button", "Clear filters")
  end

  test "mobile filter control opens a labelled filter dialog", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    refute has_element?(view, "#mobile-filters-dialog")

    render_click(view, "toggle_filters", %{})

    assert has_element?(view, ~s(#mobile-filters-dialog[role="dialog"][aria-modal="true"]))
    assert has_element?(view, "#mobile-provider-search-form")
    assert has_element?(view, "#mobile-capabilities-filter-form")
    assert has_element?(view, "#mobile-architecture-filter-form")

    render_click(view, "toggle_filters", %{})
    refute has_element?(view, "#mobile-filters-dialog")
  end

  test "architecture filter updates the URL and model rows", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    render_change(view, "filter", %{
      "_target" => ["architecture"],
      "architecture" => "moe"
    })

    assert_patch(view, "/?architecture=moe")
    assert has_element?(view, ~s(button[aria-label="Remove Architecture: MoE filter"]))
    assert has_element?(view, ~s(#models-table-body [data-architecture="moe"]))
    refute has_element?(view, ~s(#models-table-body [data-architecture="dense"]))
    refute has_element?(view, ~s(#models-table-body [data-architecture="unknown"]))

    render_click(view, "remove_filter", %{"kind" => "architecture"})
    assert_patch(view, "/")
  end

  test "model size sort presets update the URL and visible metric", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    render_change(view, "set_sort", %{"sort" => "minimum_ram_gb_desc"})

    assert_patch(view, "/?dir=desc&sort=minimum_ram_gb")

    assert has_element?(
             view,
             ~s(#sort-select option[value="minimum_ram_gb_desc"][selected])
           )

    assert has_element?(view, "#models-table-body")
    assert render(view) =~ "Min RAM"
    assert render(view) =~ "GB"
  end

  test "mobile navigation exposes primary and project links", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(
             view,
             ~s(nav[aria-label="Mobile navigation"] a[href="/history"]),
             "History"
           )

    assert has_element?(view, ~s(nav[aria-label="Mobile navigation"] a[href="/about"]), "About")

    assert has_element?(
             view,
             ~s(nav[aria-label="Mobile navigation"] a[href="https://github.com/agentjido/llm_db"]),
             "GitHub"
           )

    assert has_element?(
             view,
             ~s(nav[aria-label="Mobile navigation"] a[href*="template=model_metadata.yml"]),
             "Report incorrect model data"
           )
  end

  defp first_provider_id do
    Catalog.list_providers()
    |> List.first()
    |> Map.fetch!(:id)
    |> to_string()
  end
end
