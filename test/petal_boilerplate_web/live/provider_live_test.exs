defmodule PetalBoilerplateWeb.ProviderLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog.ProviderPage
  alias PetalBoilerplateWeb.PublicRoutes

  test "published provider pages are canonical, indexable, and deterministic", %{conn: conn} do
    assert length(ProviderPage.indexable_ids()) == 10

    for provider_id <- ProviderPage.indexable_ids() do
      {:ok, snapshot} = ProviderPage.fetch(provider_id)
      html = conn |> recycle() |> get(snapshot.route) |> html_response(200)

      assert snapshot.model_count > 0
      assert snapshot.models == Enum.sort_by(snapshot.models, &sort_key/1)
      assert snapshot.default_model_count == length(snapshot.default_models)
      assert html =~ snapshot.heading
      assert html =~ snapshot.summary
      assert html =~ ~s(<time datetime="#{snapshot.last_updated}">#{snapshot.last_updated}</time>)
      assert html =~ "Compare #{snapshot.name} models"
      assert html =~ "Newest releases"
      assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute(snapshot.route)}")
      refute html =~ ~s(name="robots" content="noindex)
      assert html =~ ~s(href="#{PublicRoutes.markdown_path(snapshot.route)}")
      assert html =~ ~s(id="quick-filters")
      assert html =~ ~s(id="related-provider-links")
      assert html =~ ~s(id="related-catalog-links")

      for related <- snapshot.related_providers do
        assert html =~ ~s(href="#{related.route}")
      end

      for related <- snapshot.catalog_links do
        assert html =~ ~s(href="#{related.route}")
      end
    end
  end

  test "Amazon Bedrock uses a hyphenated provider route", %{conn: conn} do
    assert ProviderPage.path("amazon_bedrock") == "/provider/amazon-bedrock"
    assert conn |> get("/provider/amazon-bedrock") |> html_response(200)

    assert build_conn() |> get("/provider/amazon_bedrock") |> response(404)
  end

  test "provider filters use the clean route and keep the provider scope fixed", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/provider/anthropic?caps=tools")

    assert has_element?(view, "h1", "Anthropic Claude Models")
    assert has_element?(view, ~s(#sort-select option[value="newest"][selected]))

    assert has_element?(
             view,
             ~s(#quick-filters button[phx-value-kind="anthropic"][aria-pressed="true"])
           )

    assert has_element?(view, ~s(#quick-filters button[phx-value-kind="openai"]))

    render_click(view, "toggle_filters", %{})
    refute has_element?(view, "#provider-search-form")
    assert has_element?(view, "#capabilities-filter-form")

    rendered = render(view) |> Floki.parse_fragment!()

    providers =
      rendered
      |> Floki.find("#models-table-body tr td:nth-child(2)")
      |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
      |> Enum.uniq()

    assert providers == ["anthropic"]
    refute render(view) =~ "providers=anthropic"
  end

  test "filtered and paginated provider URLs are noindex with the base canonical", %{conn: conn} do
    route = "/provider/openrouter"

    filtered_html =
      conn
      |> get(route <> "?caps=tools")
      |> html_response(200)

    assert filtered_html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute(route)}")
    assert filtered_html =~ ~s(name="robots" content="noindex, follow")

    {:ok, view, _html} = conn |> recycle() |> live(route)
    render_click(view, "page", %{"page" => "2"})
    assert_patch(view, route <> "?page=2")

    assert has_element?(
             view,
             ~s(#live-seo-metadata[data-canonical-url="#{PublicRoutes.absolute(route)}"][data-robots="noindex, follow"])
           )
  end

  test "provider directory sends approved providers to clean singular routes", %{conn: conn} do
    html = conn |> get("/providers") |> html_response(200)

    for route <- ProviderPage.routes() do
      assert html =~ ~s(href="#{route}")
    end
  end

  test "provider pages have deterministic Markdown alternatives", %{conn: conn} do
    for provider_id <- ProviderPage.indexable_ids() do
      {:ok, snapshot} = ProviderPage.fetch(provider_id)

      markdown =
        conn
        |> recycle()
        |> get(PublicRoutes.markdown_path(snapshot.route))
        |> response(200)

      assert markdown =~ "# #{snapshot.heading}"
      assert markdown =~ snapshot.summary
      assert markdown =~ "## #{snapshot.name} model list by release date"
      assert markdown =~ "## Compare other model providers"
      assert markdown =~ "## Explore related LLM model lists"
      assert markdown =~ "Canonical URL: #{PublicRoutes.absolute(snapshot.route)}"
    end
  end

  defp sort_key(model) do
    name = model.name || model.model_id || model.id || ""
    model_id = model.model_id || model.id || ""

    case parse_date(model.release_date) do
      %Date{} = date -> {0, -Date.to_gregorian_days(date), String.downcase(name), model_id}
      nil -> {1, 0, String.downcase(name), model_id}
    end
  end

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(String.slice(value, 0, 10)) do
      {:ok, date} -> date
      _other -> nil
    end
  end

  defp parse_date(_value), do: nil
end
