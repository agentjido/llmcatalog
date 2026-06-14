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

  defp first_provider_id do
    Catalog.list_providers()
    |> List.first()
    |> Map.fetch!(:id)
    |> to_string()
  end
end
