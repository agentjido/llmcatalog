defmodule PetalBoilerplate.Catalog.LandingPagesTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.Catalog.LandingPages

  test "defines the complete landing-page route set" do
    assert LandingPages.routes() == [
             "/models/long-context",
             "/models/open-weights",
             "/models/tool-calling",
             "/models/video",
             "/models/vision",
             "/rankings/ai-models",
             "/rankings/cheapest-llm-api"
           ]
  end

  test "cheapest API rows use positive paid prices in stable order" do
    snapshot = LandingPages.snapshot(:cheapest, 1)
    entries = hd(snapshot.sections).entries

    assert snapshot.total_count > 0
    assert Enum.all?(entries, &(&1.cost_in > 0 and &1.cost_out > 0))

    prices = Enum.map(entries, &{&1.cost_in, &1.cost_out})
    assert prices == Enum.sort(prices)
  end

  test "capability pages expose the stated catalog evidence" do
    vision = LandingPages.snapshot(:vision, 1)
    tools = LandingPages.snapshot(:tool_calling, 1)
    context = LandingPages.snapshot(:long_context, 1)
    open_weights = LandingPages.snapshot(:open_weights, 1)

    assert Enum.all?(hd(vision.sections).entries, fn entry ->
             MapSet.member?(entry.input_modalities, :image) and
               MapSet.member?(entry.output_modalities, :text)
           end)

    assert Enum.all?(
             hd(tools.sections).entries,
             &MapSet.member?(&1.capabilities, :tools)
           )

    assert Enum.all?(hd(context.sections).entries, fn entry ->
             entry.context >= 128_000 and entry.context <= 10_000_000
           end)

    assert hd(context.sections).entries
           |> Enum.map(& &1.context)
           |> then(&(&1 == Enum.sort(&1, :desc)))

    assert open_weights.total_count > 0
    assert Enum.all?(hd(open_weights.sections).entries, &(&1.reason == "Open weights: true"))
  end

  test "video input and output remain separate" do
    snapshot = LandingPages.snapshot(:video, 1)

    assert [input, output] = snapshot.sections
    assert input.title == "Models that accept video"
    assert output.title == "Models that generate video"
    assert input.total_count > 0
    assert output.total_count > 0
    assert Enum.all?(input.entries, &MapSet.member?(&1.input_modalities, :video))
    assert Enum.all?(output.entries, &MapSet.member?(&1.output_modalities, :video))
  end

  test "ranking hub uses separate objective sections" do
    snapshot = LandingPages.snapshot(:ai_models, 1)

    assert Enum.map(snapshot.sections, & &1.title) == [
             "Lowest paid input-token prices",
             "Largest recorded context windows",
             "Most recently updated model records"
           ]

    assert Enum.all?(snapshot.sections, &(length(&1.entries) == 10))
  end
end
