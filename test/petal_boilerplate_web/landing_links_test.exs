defmodule PetalBoilerplateWeb.LandingLinksTest do
  use ExUnit.Case, async: true

  alias PetalBoilerplate.SEOContent
  alias PetalBoilerplateWeb.LandingLinks

  test "all published landing pages are present in the internal-link graph" do
    published_routes = SEOContent.all_pages() |> Enum.map(& &1.route) |> Enum.sort()

    assert LandingLinks.landing_routes() == published_routes
  end

  test "each page links to valid pages but not to itself" do
    landing_routes = LandingLinks.landing_routes()

    for route <- landing_routes do
      target_routes = route |> LandingLinks.links_for() |> Enum.map(& &1.route)

      assert length(target_routes) >= 3
      assert length(target_routes) == length(Enum.uniq(target_routes))
      refute route in target_routes
      assert Enum.all?(target_routes, &(&1 in landing_routes))
    end
  end

  test "spoke links are reciprocal and every spoke links to both hubs" do
    hubs = ["/llm-models", "/rankings/ai-models"]
    spokes = LandingLinks.landing_routes() -- hubs

    for route <- spokes do
      target_routes = route |> LandingLinks.links_for() |> Enum.map(& &1.route)
      assert Enum.all?(hubs, &(&1 in target_routes))
    end

    for source <- LandingLinks.landing_routes(),
        target <- source |> LandingLinks.links_for() |> Enum.map(& &1.route) do
      reciprocal_routes = target |> LandingLinks.links_for() |> Enum.map(& &1.route)
      assert source in reciprocal_routes
    end
  end

  test "breadcrumbs show the expected parent hub" do
    assert Enum.map(LandingLinks.breadcrumbs_for("/models/vision"), & &1.route) == [
             "/",
             "/llm-models",
             "/models/vision"
           ]

    assert Enum.map(
             LandingLinks.breadcrumbs_for("/rankings/cheapest-llm-api"),
             & &1.route
           ) == [
             "/",
             "/rankings/ai-models",
             "/rankings/cheapest-llm-api"
           ]
  end
end
