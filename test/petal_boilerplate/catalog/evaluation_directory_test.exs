defmodule PetalBoilerplate.Catalog.EvaluationDirectoryTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Filters
  alias PetalBoilerplate.Catalog.LandingPages
  alias PetalBoilerplate.Catalog.LLMModelsList
  alias PetalBoilerplate.Catalog.ProviderDirectory
  alias PetalBoilerplateWeb.PublicRoutes

  test "packaged catalog includes direct and gateway Jev evaluation specs" do
    snapshot = LandingPages.evaluation_snapshot(Catalog.list_all_models())

    specs_by_provider =
      Map.new(snapshot.sections, fn section ->
        {section.title, Enum.map(section.entries, & &1.model_id)}
      end)

    for {provider, expected_specs} <- %{
          "Cloudflare workers ai" => ["typesafe/jev"],
          "Openrouter" => ["typesafe/jev-1.13", "~typesafe/jev-latest"],
          "Typesafe" => ["jev-1.13.0", "jev-latest", "jev-preview"],
          "Vercel" => ["typesafe-ai/jev"]
        } do
      assert MapSet.subset?(
               MapSet.new(expected_specs),
               MapSet.new(Map.fetch!(specs_by_provider, provider))
             )
    end

    assert Enum.all?(snapshot.sections, fn section ->
             Enum.all?(section.entries, &MapSet.member?(&1.representative.__caps, :evaluate))
           end)
  end

  test "evaluation list uses only explicit active capability across providers" do
    base = hd(Catalog.list_all_models())

    evaluation =
      base
      |> Map.merge(%{
        provider: :example_gateway,
        model_id: "team/choice-v1",
        name: "Choice V1",
        capabilities: %{evaluate: true, chat: false},
        __caps: MapSet.new([:evaluate]),
        __context: 32_000,
        __cost_in: 0.042,
        __cost_out: 0.0,
        deprecated: false,
        retired: false,
        catalog_only: true
      })

    no_evaluate = %{evaluation | model_id: "team/json-v1", capabilities: %{json: %{native: true}}}
    deprecated = %{evaluation | model_id: "team/old", deprecated: true}
    retired = %{evaluation | model_id: "team/retired", retired: true}

    snapshot = LandingPages.evaluation_snapshot([evaluation, no_evaluate, deprecated, retired])

    assert snapshot.total_count == 1
    assert snapshot.provider_count == 1
    assert [%{title: "Example gateway", entries: [entry]}] = snapshot.sections
    assert entry.model_id == "team/choice-v1"
    assert entry.representative.provider == :example_gateway

    assert PublicRoutes.model_path(entry.representative) ==
             "/models/example_gateway/team/choice-v1"

    assert entry.context == 32_000
    assert entry.cost_in == 0.042
    assert entry.reason =~ "Catalog only"
    refute LLMModelsList.eligible_offer?(evaluation)
  end

  test "Evaluate filter matches the explicit capability" do
    filters = Filters.from_params(%{"caps" => "evaluate"})
    assert filters.capabilities.evaluate
    assert Filters.to_params(filters)["caps"] =~ "evaluate"

    models = Catalog.list_models(Catalog.list_all_models(), filters, Catalog.default_sort())
    assert Enum.all?(models, &MapSet.member?(&1.__caps, :evaluate))
    assert Enum.any?(models, &(&1.provider == :typesafe))
  end

  test "provider directory includes every provider and counts catalog records" do
    providers = [
      %{id: :alpha, name: "Alpha"},
      %{id: :beta, name: "Beta"},
      %{id: :empty, name: "Empty"}
    ]

    models = [
      %{provider: :alpha, capabilities: %{evaluate: true}, deprecated: false, retired: false},
      %{provider: :alpha, capabilities: %{evaluate: true}, deprecated: true, retired: false},
      %{provider: :alpha, capabilities: %{}, deprecated: false, retired: false},
      %{provider: :beta, capabilities: %{evaluate: true}, deprecated: false, retired: false}
    ]

    entries = ProviderDirectory.entries(providers, models)

    assert Enum.map(entries, &{&1.id, &1.model_count, &1.evaluation_count}) == [
             {"alpha", 3, 1},
             {"beta", 1, 1},
             {"empty", 0, 0}
           ]

    assert ProviderDirectory.catalog_path("alpha")
           |> URI.parse()
           |> Map.fetch!(:query)
           |> URI.decode_query() == %{
             "providers" => "alpha",
             "allowed_only" => "false",
             "show_deprecated" => "true"
           }
  end
end
