defmodule PetalBoilerplateWeb.MarkdownContent do
  @moduledoc """
  Builds deterministic Markdown representations of public pages.
  """

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.PublicRoutes

  @history_limit 50

  @spec eligible_public_path?(String.t()) :: boolean()
  def eligible_public_path?(path) when path in ["/", "/about", "/history"], do: true

  def eligible_public_path?(path) when is_binary(path) do
    match?({:ok, _model}, PublicRoutes.model_from_path(path))
  end

  @spec resolve(String.t(), String.t()) :: {:ok, String.t()} | :no_match
  def resolve("/", canonical_url), do: {:ok, home_markdown(canonical_url)}
  def resolve("/about", canonical_url), do: {:ok, about_markdown(canonical_url)}
  def resolve("/history", canonical_url), do: {:ok, history_markdown(canonical_url)}

  def resolve(path, canonical_url) do
    case PublicRoutes.model_from_path(path) do
      {:ok, model} -> {:ok, model_markdown(model, canonical_url)}
      :error -> :no_match
    end
  end

  defp home_markdown(canonical_url) do
    model_count = Catalog.total_model_count()
    provider_count = length(Catalog.list_providers())
    endpoint_url = PetalBoilerplateWeb.Endpoint.url()

    """
    # LLM Model Database

    Browse and compare #{Catalog.format_number(model_count)} large language models from #{provider_count} providers.

    Filter models by provider, capabilities, pricing, modalities, context windows, and output limits.

    - [Browse models](#{canonical_url})
    - [About llmdb.xyz](#{endpoint_url}/about)
    - [Recent model history](#{endpoint_url}/history)
    - [XML sitemap](#{endpoint_url}/sitemap.xml)
    - [RSS history feed](#{endpoint_url}/feed)
    - [LLM retrieval guidance](#{endpoint_url}/llms.txt)
    - MCP endpoint: `#{endpoint_url}/api/mcp`
    """
  end

  defp about_markdown(canonical_url) do
    model_count = Catalog.total_model_count()
    provider_count = length(Catalog.list_providers())

    """
    # About llmdb.xyz

    llmdb.xyz is a database of #{Catalog.format_number(model_count)} large language models from #{provider_count} providers.

    The catalog supports comparisons of model capabilities, pricing, context windows, output limits, modalities, aliases, and lifecycle data.

    The site uses the open-source `llm_db` Elixir package as its catalog source.

    Canonical URL: #{canonical_url}
    """
  end

  defp history_markdown(canonical_url) do
    events =
      case history_module().recent(@history_limit) do
        {:ok, events} -> events
        _ -> []
      end

    event_markdown =
      case events do
        [] ->
          "History data is not available."

        entries ->
          entries
          |> Enum.map(&format_history_event/1)
          |> Enum.join("\n")
      end

    """
    # Recent LLM Model History

    Reverse-chronological model metadata changes from the bundled `llm_db` history.

    Canonical URL: #{canonical_url}

    ## Latest events

    #{event_markdown}
    """
  end

  defp model_markdown(model, canonical_url) do
    model_id = model.model_id
    title = model.name || model_id

    """
    # #{title}

    - Provider: #{model.provider}
    - Model ID: `#{model_id}`
    - Family: #{value_or_na(model.family)}
    - Deprecated: #{yes_no(model.deprecated)}
    - Release date: #{value_or_na(Map.get(model, :release_date))}
    - Last updated: #{value_or_na(Map.get(model, :last_updated))}
    - Context window: #{number_or_na(Map.get(model, :__context))}
    - Maximum output: #{number_or_na(Map.get(model, :__output))}
    - Input cost per million tokens: #{cost_or_na(Map.get(model, :__cost_in))}
    - Output cost per million tokens: #{cost_or_na(Map.get(model, :__cost_out))}
    - Input modalities: #{list_or_na(Map.get(model, :__in))}
    - Output modalities: #{list_or_na(Map.get(model, :__out))}
    - Capabilities: #{list_or_na(Map.get(model, :__caps))}
    - Aliases: #{list_or_na(model.aliases)}
    - Tags: #{list_or_na(model.tags)}

    Canonical URL: #{canonical_url}
    """
  end

  defp format_history_event(event) do
    provider = map_get(event, "provider", :provider) || "unknown"
    model_id = map_get(event, "model_id", :model_id) || "unknown"
    event_type = map_get(event, "type", :type) || "changed"
    captured_at = map_get(event, "captured_at", :captured_at) || "unknown time"
    model_url = PublicRoutes.absolute(PublicRoutes.model_path(provider, model_id))

    changes =
      event
      |> map_get("changes", :changes)
      |> List.wrap()
      |> Enum.map(fn change ->
        operation = map_get(change, "op", :op) || "changed"
        path = map_get(change, "path", :path) || "model"
        "`#{path}` #{operation}"
      end)
      |> case do
        [] -> "model record"
        items -> Enum.join(items, ", ")
      end

    "- **#{Phoenix.Naming.humanize(event_type)}** [#{provider}:#{model_id}](#{model_url}) at #{captured_at}: #{changes}"
  end

  defp value_or_na(value) when value in [nil, ""], do: "N/A"
  defp value_or_na(value), do: to_string(value)

  defp number_or_na(value) when is_integer(value) and value > 0, do: Catalog.format_number(value)
  defp number_or_na(_value), do: "N/A"

  defp cost_or_na(value) when is_number(value), do: Catalog.format_cost(value)
  defp cost_or_na(_value), do: "N/A"

  defp yes_no(true), do: "Yes"
  defp yes_no(_value), do: "No"

  defp list_or_na(%MapSet{} = values), do: values |> MapSet.to_list() |> list_or_na()
  defp list_or_na([]), do: "N/A"
  defp list_or_na(nil), do: "N/A"
  defp list_or_na(values) when is_list(values), do: values |> Enum.map_join(", ", &to_string/1)
  defp list_or_na(value), do: to_string(value)

  defp map_get(nil, _string_key, _atom_key), do: nil

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end
end
