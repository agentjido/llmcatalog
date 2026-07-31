defmodule PetalBoilerplate.Catalog.LLMModelsListTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LLMModelsList

  test "builds a deduplicated list of active executable text models" do
    snapshot = LLMModelsList.snapshot()
    model_ids = Enum.map(snapshot.entries, & &1.model_id)

    assert snapshot.model_identity_count > 0
    assert snapshot.eligible_offer_count >= snapshot.model_identity_count
    assert snapshot.provider_count > 0
    assert snapshot.total_pages > 1
    assert length(snapshot.entries) == snapshot.page_size
    assert Enum.uniq(model_ids) == model_ids

    assert Enum.all?(snapshot.entries, fn entry ->
             entry.provider_count == length(entry.providers) and
               LLMModelsList.eligible_offer?(entry.representative)
           end)
  end

  test "orders pages by latest update with stable, non-overlapping identities" do
    first = LLMModelsList.snapshot(1)
    second = LLMModelsList.snapshot(2)

    first_ids = MapSet.new(Enum.map(first.entries, & &1.model_id))
    second_ids = MapSet.new(Enum.map(second.entries, & &1.model_id))
    dates = Enum.map(first.entries, &(&1.last_updated || ""))

    assert dates == Enum.sort(dates, :desc)
    assert MapSet.disjoint?(first_ids, second_ids)
  end

  test "groups a specific vendor-prefixed ID with its plain provider ID" do
    namespaced = Catalog.get_model("openrouter", "anthropic/claude-opus-5")
    plain = Catalog.get_model("anthropic", "claude-opus-5")

    assert LLMModelsList.identity_key(namespaced) == "claude-opus-5"
    assert LLMModelsList.identity_key(plain) == "claude-opus-5"
  end

  test "uses database aliases to connect dated and punctuation variants" do
    model = hd(LLMModelsList.eligible_offers())

    dated =
      Map.merge(model, %{
        provider: :anthropic,
        model_id: "claude-haiku-4-5-20251001",
        name: "Claude Haiku 4.5",
        aliases: ["claude-haiku-4.5"]
      })

    dotted =
      Map.merge(model, %{
        provider: :openrouter,
        model_id: "anthropic/claude-haiku-4.5",
        name: "Anthropic: Claude Haiku 4.5",
        aliases: []
      })

    [entry] = LLMModelsList.grouped_entries([dated, dotted])

    assert entry.providers == ["anthropic", "openrouter"]
    assert entry.provider_count == 2
  end

  test "groups the published Claude Fable offers by database aliases" do
    entries =
      LLMModelsList.eligible_offers()
      |> LLMModelsList.grouped_entries()

    fable = Enum.find(entries, &(&1.model_id == "claude-fable-5"))

    assert fable
    assert MapSet.subset?(MapSet.new(["anthropic", "openrouter"]), MapSet.new(fable.providers))
    assert fable.provider_count > 1
  end

  test "does not group matching names without model ID or alias evidence" do
    model = hd(LLMModelsList.eligible_offers())

    first =
      Map.merge(model, %{
        provider: :first_provider,
        model_id: "first-model-1",
        name: "Shared Display Name",
        aliases: []
      })

    second =
      Map.merge(model, %{
        provider: :second_provider,
        model_id: "second-model-2",
        name: "Shared Display Name",
        aliases: []
      })

    assert length(LLMModelsList.grouped_entries([first, second])) == 2
  end

  test "requires a typed text execution path for each included provider offer" do
    image_offer = Catalog.get_model("openrouter", "google/gemini-3.1-flash-lite-image")
    text_offer = Catalog.get_model("google", "gemini-3.1-flash-lite-image")

    refute LLMModelsList.eligible_offer?(image_offer)
    assert LLMModelsList.eligible_offer?(text_offer)
  end

  test "does not prefer a negative sentinel price when a valid offer exists" do
    model = hd(LLMModelsList.eligible_offers())
    valid = Map.merge(model, %{provider: :valid_price, __cost_in: 1.0, __cost_out: 2.0})

    sentinel =
      Map.merge(model, %{
        provider: :sentinel_price,
        __cost_in: -1_000_000,
        __cost_out: -1_000_000
      })

    [entry] = LLMModelsList.grouped_entries([sentinel, valid])

    assert entry.cost_in == 1.0
    assert entry.cost_out == 2.0
    assert entry.representative.provider == :valid_price
  end
end
