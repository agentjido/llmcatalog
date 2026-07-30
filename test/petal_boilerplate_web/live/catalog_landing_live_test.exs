defmodule PetalBoilerplateWeb.CatalogLandingLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog.LandingPages
  alias PetalBoilerplate.SEOContent
  alias PetalBoilerplateWeb.LandingLinks
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  test "renders every catalog landing page with its editorial content", %{conn: conn} do
    for route <- LandingPages.routes() do
      page = SEOContent.get_page!(route)

      html =
        conn
        |> recycle()
        |> get(route)
        |> html_response(200)

      assert html =~ page.title
      assert html =~ page.methodology.name
      assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute(route)}")
      refute html =~ ~s(name="robots" content="noindex)
      assert html =~ ~s(href="#{PublicRoutes.markdown_path(route)}")

      document = Floki.parse_document!(html)

      pack_routes =
        document
        |> Floki.find("#related-model-lists a")
        |> Floki.attribute("href")

      expected_routes = route |> LandingLinks.links_for() |> Enum.map(& &1.route)

      assert pack_routes == expected_routes
      refute route in pack_routes
      assert Floki.find(document, ~s(nav[aria-label="Breadcrumb"])) != []
    end
  end

  test "includes all approved landing pages in the curated sitemap source" do
    assert Enum.all?(LandingPages.routes(), &(&1 in SEO.search_indexable_paths()))
    assert length(SEO.search_indexable_paths()) == 10
  end

  test "pagination keeps the base canonical and noindex directive", %{conn: conn} do
    route = "/models/vision"

    html =
      conn
      |> get(route <> "?page=2")
      |> html_response(200)

    assert html =~ ~s(rel="canonical" href="#{PublicRoutes.absolute(route)}")
    assert html =~ ~s(name="robots" content="noindex, follow")
  end
end
