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
    assert has_element?(view, ~s(button[aria-label="Clear filters"]))
  end

  test "clear filters preserves search", %{conn: conn} do
    provider_id = first_provider_id()

    {:ok, view, _html} = live(conn, "/?q=gpt&providers=#{provider_id}&caps=tools")

    assert has_element?(view, ~s(button[aria-label="Clear filters"]))

    render_click(view, "clear_filters", %{})

    assert_patch(view, "/?q=gpt")
    assert has_element?(view, ~s(button[aria-label="Clear search"]))
    refute has_element?(view, ~s(button[aria-label="Clear filters"]))
  end

  test "filter control opens a labelled filter dialog", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, ~s(#quick-filters[aria-label="Quick filters"]))
    assert has_element?(view, ~s(#quick-filters button[phx-click="quick_filter"]))
    refute has_element?(view, "#filters-dialog")

    render_click(view, "toggle_filters", %{})

    assert has_element?(view, ~s(#filters-dialog[role="dialog"][aria-modal="true"]))
    refute has_element?(view, "#filters-dialog summary", "Quick filters")
    assert has_element?(view, "#provider-search-form")
    assert has_element?(view, "#capabilities-filter-form")
    assert has_element?(view, "#architecture-filter-form")
    assert has_element?(view, "#catalog-recency-form")

    render_click(view, "toggle_filters", %{})
    refute has_element?(view, "#filters-dialog")
  end

  test "model rows hide unknown architecture badges", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/?architecture=unknown")

    assert has_element?(view, "#models-table-body tr")
    refute has_element?(view, ~s(span[data-architecture="unknown"]))
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

  test "site header exposes social and theme actions without developer menu links", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(
             view,
             ~s(nav[aria-label="Site navigation"] a[href="/history"]),
             "Model history"
           )

    assert has_element?(view, ~s(nav[aria-label="Site navigation"] a[href="/about"]), "About")

    assert has_element?(
             view,
             ~s(header a[aria-label="View llmdb on GitHub"])
           )

    assert has_element?(
             view,
             ~s(header a[aria-label="Join Discord"][href="https://jido.run/discord"])
           )

    assert has_element?(view, ~s(header button[aria-label="Change color theme"]))
    refute has_element?(view, ~s(nav[aria-label="Site navigation"] a[href="/developers"]))
    refute has_element?(view, ~s(nav[aria-label="Site navigation"] a[href="/openapi.json"]))

    assert has_element?(
             view,
             ~s(nav[aria-label="Site navigation"] a[href*="template=model_metadata.yml"]),
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
