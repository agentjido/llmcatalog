defmodule PetalBoilerplate.Catalog.LandingPages do
  @moduledoc """
  Builds objective catalog datasets for search landing pages.

  The datasets use explicit catalog fields. They do not score model quality.
  """

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LLMModelsList

  @page_size 50
  @long_context_min 128_000
  @long_context_max 10_000_000

  @pages %{
    cheapest: "/rankings/cheapest-llm-api",
    vision: "/models/vision",
    tool_calling: "/models/tool-calling",
    long_context: "/models/long-context",
    open_weights: "/models/open-weights",
    ai_models: "/rankings/ai-models",
    video: "/models/video"
  }

  @type action ::
          :cheapest
          | :vision
          | :tool_calling
          | :long_context
          | :open_weights
          | :ai_models
          | :video

  @spec routes() :: [String.t()]
  def routes, do: @pages |> Map.values() |> Enum.sort()

  @spec route_for(action()) :: String.t()
  def route_for(action), do: Map.fetch!(@pages, action)

  @spec action_for_route(String.t()) :: {:ok, action()} | :error
  def action_for_route(route) do
    case Enum.find(@pages, fn {_action, page_route} -> page_route == route end) do
      {action, _route} -> {:ok, action}
      nil -> :error
    end
  end

  @spec snapshot(action(), pos_integer()) :: map()
  def snapshot(:cheapest, page), do: cheapest_snapshot(page)
  def snapshot(:vision, page), do: grouped_snapshot(:vision, page)
  def snapshot(:tool_calling, page), do: grouped_snapshot(:tool_calling, page)
  def snapshot(:long_context, page), do: grouped_snapshot(:long_context, page)
  def snapshot(:open_weights, page), do: grouped_snapshot(:open_weights, page)
  def snapshot(:ai_models, _page), do: ranking_snapshot()
  def snapshot(:video, _page), do: video_snapshot()

  @spec markdown_rows(action(), non_neg_integer()) :: [map()]
  def markdown_rows(action, limit \\ 50) do
    snapshot = snapshot(action, 1)

    snapshot.sections
    |> Enum.flat_map(fn section ->
      Enum.map(section.entries, &Map.put(&1, :section, section.title))
    end)
    |> Enum.take(limit)
  end

  defp cheapest_snapshot(page) do
    entries =
      LLMModelsList.eligible_offers()
      |> Enum.filter(&paid_token_offer?/1)
      |> Enum.sort_by(fn model ->
        {
          model.__cost_in,
          model.__cost_out,
          to_string(model.provider),
          String.downcase(model.name || model.model_id),
          model.model_id
        }
      end)
      |> Enum.map(&offer_entry/1)

    paged_snapshot(
      entries,
      page,
      "Lowest input-token prices",
      "Paid text-generation offers with known input and output token prices, ordered by input price.",
      "Paid text API offers"
    )
  end

  defp grouped_snapshot(action, page) do
    entries =
      LLMModelsList.eligible_offers()
      |> Enum.filter(&group_filter(&1, action))
      |> LLMModelsList.grouped_entries()
      |> sort_grouped(action)
      |> Enum.map(&Map.put(&1, :reason, inclusion_reason(action, &1)))

    {section_title, section_description, count_label} = grouped_labels(action)
    paged_snapshot(entries, page, section_title, section_description, count_label)
  end

  defp ranking_snapshot do
    cheapest =
      LLMModelsList.eligible_offers()
      |> Enum.filter(&paid_token_offer?/1)
      |> Enum.sort_by(&{&1.__cost_in, &1.__cost_out, to_string(&1.provider), &1.model_id})
      |> Enum.take(10)
      |> Enum.map(&offer_entry/1)

    grouped = LLMModelsList.eligible_offers() |> LLMModelsList.grouped_entries()

    longest =
      grouped
      |> Enum.filter(&valid_long_context?/1)
      |> Enum.sort_by(&{-&1.context, String.downcase(&1.name), &1.model_id})
      |> Enum.take(10)
      |> Enum.map(&Map.put(&1, :reason, "Recorded context window"))

    latest =
      grouped
      |> Enum.filter(&(not is_nil(&1.last_updated)))
      |> Enum.sort_by(&{&1.last_updated, String.downcase(&1.name), &1.model_id}, :desc)
      |> Enum.take(10)
      |> Enum.map(&Map.put(&1, :reason, "Latest catalog update"))

    sections = [
      section(
        "Lowest paid input-token prices",
        "Provider offers ordered by the known input-token price.",
        cheapest
      ),
      section(
        "Largest recorded context windows",
        "Model identities ordered by context. Values above 10 million tokens are excluded.",
        longest
      ),
      section(
        "Most recently updated model records",
        "Model identities ordered by the latest valid catalog date.",
        latest
      )
    ]

    base_snapshot(sections, length(grouped), "Active model identities")
  end

  defp video_snapshot do
    offers =
      Catalog.list_all_models()
      |> Enum.filter(&active_allowed_offer?/1)

    input_entries =
      offers
      |> Enum.filter(&modality?(&1.__in, :video))
      |> LLMModelsList.grouped_entries()
      |> Enum.sort_by(&stable_name_key/1)
      |> Enum.take(@page_size)
      |> Enum.map(&Map.put(&1, :reason, "Video input"))

    output_entries =
      offers
      |> Enum.filter(&modality?(&1.__out, :video))
      |> LLMModelsList.grouped_entries()
      |> Enum.sort_by(&stable_name_key/1)
      |> Enum.take(@page_size)
      |> Enum.map(&Map.put(&1, :reason, "Video output"))

    input_count =
      offers
      |> Enum.filter(&modality?(&1.__in, :video))
      |> LLMModelsList.grouped_entries()
      |> length()

    output_count =
      offers
      |> Enum.filter(&modality?(&1.__out, :video))
      |> LLMModelsList.grouped_entries()
      |> length()

    sections = [
      section(
        "Models that accept video",
        "These model identities list video as an input modality.",
        input_entries,
        input_count
      ),
      section(
        "Models that generate video",
        "These model identities list video as an output modality.",
        output_entries,
        output_count
      )
    ]

    base_snapshot(sections, input_count + output_count, "Video modality entries")
  end

  defp paged_snapshot(entries, page, section_title, section_description, count_label) do
    {page_entries, total, total_pages, page} = Catalog.paginate(entries, page, @page_size)

    section =
      section(section_title, section_description, page_entries, total)

    base_snapshot([section], total, count_label)
    |> Map.merge(%{
      page: page,
      total_pages: total_pages,
      page_size: @page_size,
      provider_count: provider_count(entries),
      last_updated: latest_date(entries)
    })
  end

  defp base_snapshot(sections, total_count, count_label) do
    visible_entries = Enum.flat_map(sections, & &1.entries)

    %{
      sections: sections,
      total_count: total_count,
      count_label: count_label,
      provider_count: provider_count(visible_entries),
      last_updated: latest_date(visible_entries),
      page: 1,
      total_pages: 1,
      page_size: @page_size
    }
  end

  defp section(title, description, entries, total_count \\ nil) do
    %{
      title: title,
      description: description,
      entries: entries,
      total_count: total_count || length(entries)
    }
  end

  defp offer_entry(model) do
    %{
      model_id: model.model_id,
      name: model.name || model.model_id,
      representative: model,
      providers: [to_string(model.provider)],
      provider_count: 1,
      context: model.__context,
      output: model.__output,
      cost_in: model.__cost_in,
      cost_out: model.__cost_out,
      capabilities: model.__caps,
      input_modalities: model.__in,
      output_modalities: model.__out,
      last_updated: model.last_updated,
      reason: "Known paid token prices"
    }
  end

  defp paid_token_offer?(model) do
    is_number(model.__cost_in) and model.__cost_in > 0 and
      is_number(model.__cost_out) and model.__cost_out > 0
  end

  defp group_filter(model, :vision), do: modality?(model.__in, :image)
  defp group_filter(model, :tool_calling), do: MapSet.member?(model.__caps, :tools)
  defp group_filter(model, :long_context), do: valid_long_context?(model)

  defp group_filter(model, :open_weights) do
    model
    |> Map.get(:extra)
    |> case do
      extra when is_map(extra) ->
        Map.get(extra, :open_weights) == true or Map.get(extra, "open_weights") == true

      _other ->
        false
    end
  end

  defp sort_grouped(entries, :long_context) do
    Enum.sort_by(entries, &{-&1.context, String.downcase(&1.name), &1.model_id})
  end

  defp sort_grouped(entries, _action), do: Enum.sort_by(entries, &stable_name_key/1)

  defp grouped_labels(:vision) do
    {
      "Vision models with image input",
      "Active text-generation model identities that accept image input.",
      "Vision model identities"
    }
  end

  defp grouped_labels(:tool_calling) do
    {
      "Models with tool-calling metadata",
      "Active text-generation model identities with the tools capability.",
      "Tool-calling identities"
    }
  end

  defp grouped_labels(:long_context) do
    {
      "Largest context windows",
      "Active text-generation identities from 128,000 through 10 million tokens.",
      "Long-context identities"
    }
  end

  defp grouped_labels(:open_weights) do
    {
      "Models marked as open weights",
      "Active text-generation identities whose catalog metadata sets open_weights to true.",
      "Open-weight identities"
    }
  end

  defp inclusion_reason(:vision, _entry), do: "Image input and text output"
  defp inclusion_reason(:tool_calling, _entry), do: "Tools capability"
  defp inclusion_reason(:long_context, entry), do: "#{entry.context} token context"
  defp inclusion_reason(:open_weights, _entry), do: "Open weights: true"

  defp valid_long_context?(model) do
    context = Map.get(model, :context) || Map.get(model, :__context)
    is_number(context) and context >= @long_context_min and context <= @long_context_max
  end

  defp active_allowed_offer?(model) do
    model.__allowed? == true and model.deprecated != true and model.retired != true
  end

  defp modality?(%MapSet{} = values, modality) do
    MapSet.member?(values, modality) or MapSet.member?(values, to_string(modality))
  end

  defp modality?(_values, _modality), do: false

  defp stable_name_key(entry),
    do: {String.downcase(entry.name), entry.model_id, Enum.join(entry.providers, ",")}

  defp provider_count(entries) do
    entries
    |> Enum.flat_map(& &1.providers)
    |> Enum.uniq()
    |> length()
  end

  defp latest_date(entries) do
    entries
    |> Enum.map(& &1.last_updated)
    |> Enum.filter(&valid_date?/1)
    |> Enum.max(fn -> nil end)
  end

  defp valid_date?(value) when is_binary(value), do: match?({:ok, _}, Date.from_iso8601(value))
  defp valid_date?(_value), do: false
end
