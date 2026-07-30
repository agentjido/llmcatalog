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
