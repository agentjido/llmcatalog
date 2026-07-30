defmodule PetalBoilerplate.Catalog.LLMModelsList do
  @moduledoc """
  Builds the active language-model list used by the SEO landing page.

  The source catalog contains provider offers. This module groups those offers by
  a conservative normalized model ID and keeps only active offers with known text
  execution.
  """

  alias PetalBoilerplate.Catalog

  @page_size 50

  @type entry :: %{
          model_id: String.t(),
          name: String.t(),
          representative: map(),
          providers: [String.t()],
          provider_count: pos_integer(),
          context: non_neg_integer(),
          output: non_neg_integer(),
          cost_in: number() | nil,
          cost_out: number() | nil,
          capabilities: MapSet.t(),
          input_modalities: MapSet.t(),
          output_modalities: MapSet.t(),
          last_updated: String.t() | nil
        }

  @spec snapshot(pos_integer(), pos_integer()) :: map()
  def snapshot(page \\ 1, page_size \\ @page_size) do
    offers = eligible_offers()
    entries = grouped_entries(offers)

    {page_entries, total, total_pages, page} = Catalog.paginate(entries, page, page_size)

    %{
      catalog_offer_count: Catalog.total_model_count(),
      eligible_offer_count: length(offers),
      model_identity_count: total,
      provider_count: offers |> Enum.map(&to_string(&1.provider)) |> Enum.uniq() |> length(),
      last_updated: entries |> Enum.map(& &1.last_updated) |> latest_date(),
      entries: page_entries,
      page: page,
      page_size: page_size,
      total_pages: total_pages
    }
  end

  @doc """
  Returns the active provider offers that meet the base text-model rules.
  """
  @spec eligible_offers() :: [map()]
  def eligible_offers do
    Catalog.list_all_models()
    |> Enum.filter(&eligible_offer?/1)
  end

  @doc """
  Groups provider offers into conservative model identities.
  """
  @spec grouped_entries([map()]) :: [entry()]
  def grouped_entries(offers) when is_list(offers) do
    offers
    |> Enum.group_by(&identity_key/1)
    |> Enum.map(fn {model_id, model_offers} -> build_entry(model_id, model_offers) end)
    |> Enum.sort(&entry_before?/2)
  end

  @spec eligible_offer?(map()) :: boolean()
  def eligible_offer?(model) do
    Map.get(model, :__allowed?) == true and
      Map.get(model, :catalog_only) != true and
      Map.get(model, :deprecated) != true and
      Map.get(model, :retired) != true and
      text_execution_supported?(Map.get(model, :execution)) and
      modality?(Map.get(model, :__in), :text) and
      modality?(Map.get(model, :__out), :text)
  end

  @doc """
  Returns a conservative cross-provider identity key.

  Provider catalogs often prefix a specific model ID with a vendor namespace.
  The namespace is removed only when the remaining ID is specific and agrees
  with the model name. Short generic IDs remain unchanged.
  """
  @spec identity_key(map()) :: String.t()
  def identity_key(model) do
    model_id = model.model_id
    leaf_id = model_id |> String.split("/") |> List.last()

    if leaf_id != model_id and specific_model_id?(leaf_id) and
         model_name_matches_id?(Map.get(model, :name), leaf_id) do
      leaf_id
    else
      model_id
    end
  end

  defp build_entry(model_id, offers) do
    representative = Enum.min_by(offers, &offer_rank/1)

    %{
      model_id: model_id,
      name: preferred_name(offers, model_id),
      representative: representative,
      providers: offers |> Enum.map(&to_string(&1.provider)) |> Enum.uniq() |> Enum.sort(),
      provider_count: offers |> Enum.map(&to_string(&1.provider)) |> Enum.uniq() |> length(),
      context: offers |> Enum.map(&Map.get(&1, :__context)) |> max_number(),
      output: offers |> Enum.map(&Map.get(&1, :__output)) |> max_number(),
      cost_in: Map.get(representative, :__cost_in),
      cost_out: Map.get(representative, :__cost_out),
      capabilities: union_sets(offers, :__caps),
      input_modalities: union_sets(offers, :__in),
      output_modalities: union_sets(offers, :__out),
      last_updated: offers |> Enum.map(&Map.get(&1, :last_updated)) |> latest_date()
    }
  end

  defp offer_rank(offer) do
    input_cost = Map.get(offer, :__cost_in)
    output_cost = Map.get(offer, :__cost_out)
    valid_input? = valid_cost?(input_cost)
    valid_output? = valid_cost?(output_cost)

    {
      if(valid_input?, do: 0, else: 1),
      if(valid_input?, do: input_cost, else: 0),
      if(valid_output?, do: output_cost, else: 0),
      to_string(offer.provider)
    }
  end

  defp valid_cost?(cost), do: is_number(cost) and cost >= 0

  defp preferred_name(offers, model_id) do
    offers
    |> Enum.map(&Map.get(&1, :name))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.frequencies()
    |> Enum.max_by(
      fn {name, count} -> {count, String.length(name), name} end,
      fn -> {model_id, 1} end
    )
    |> elem(0)
  end

  defp union_sets(offers, field) do
    Enum.reduce(offers, MapSet.new(), fn offer, values ->
      case Map.get(offer, field) do
        %MapSet{} = offer_values -> MapSet.union(values, offer_values)
        _ -> values
      end
    end)
  end

  defp max_number(values) do
    values
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> 0 end)
  end

  defp latest_date(values) do
    values
    |> Enum.filter(&valid_date?/1)
    |> Enum.max(fn -> nil end)
  end

  defp valid_date?(value) when is_binary(value) do
    match?({:ok, _date}, Date.from_iso8601(value))
  end

  defp valid_date?(_value), do: false

  defp specific_model_id?(model_id) do
    String.length(model_id) >= 6 and
      (String.contains?(model_id, ["-", "_", "."]) or String.match?(model_id, ~r/\d/))
  end

  defp model_name_matches_id?(name, model_id) when is_binary(name) do
    normalized_name = normalize_identity_text(name)
    normalized_id = normalize_identity_text(model_id)

    normalized_name == normalized_id or String.ends_with?(normalized_name, "-" <> normalized_id)
  end

  defp model_name_matches_id?(_name, _model_id), do: false

  defp normalize_identity_text(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp text_execution_supported?(execution) when is_map(execution) do
    text_execution = Map.get(execution, :text) || Map.get(execution, "text")

    is_map(text_execution) and
      (Map.get(text_execution, :supported) == true or
         Map.get(text_execution, "supported") == true)
  end

  defp text_execution_supported?(_execution), do: false

  defp modality?(%MapSet{} = values, modality) do
    MapSet.member?(values, modality) or MapSet.member?(values, to_string(modality))
  end

  defp modality?(_values, _modality), do: false

  defp entry_before?(left, right) do
    cond do
      (left.last_updated || "") != (right.last_updated || "") ->
        (left.last_updated || "") > (right.last_updated || "")

      String.downcase(left.name) != String.downcase(right.name) ->
        String.downcase(left.name) < String.downcase(right.name)

      true ->
        left.model_id <= right.model_id
    end
  end
end
