defmodule PetalBoilerplate.Catalog.ProviderPage do
  @moduledoc """
  Builds the small, approved set of provider pages and their search visibility.

  Provider pages use exact catalog records and a stable release-date-first
  order. Use `:index` for sitemap pages and `:noindex` for routable preview pages.
  Providers that are not in this module continue to use catalog filters.
  """

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Filters
  alias PetalBoilerplate.Catalog.ProviderDirectory

  @providers %{
    "amazon_bedrock" => %{
      slug: "amazon-bedrock",
      name: "Amazon Bedrock",
      title: "Amazon Bedrock Models, Prices, and API Capabilities",
      heading: "Amazon Bedrock Models: Prices, Context Windows, and Capabilities",
      description:
        "Compare Amazon Bedrock model records, prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["Amazon Bedrock models", "Bedrock model list", "Amazon Bedrock pricing"],
      search_visibility: :index,
      live_action: :provider_amazon_bedrock
    },
    "anthropic" => %{
      name: "Anthropic",
      title: "Anthropic Claude Models, Prices, and API Capabilities",
      heading: "Anthropic Claude Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare Anthropic Claude model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["Claude models", "Anthropic models", "Claude model list"],
      search_visibility: :index,
      live_action: :provider_anthropic
    },
    "azure" => %{
      name: "Azure",
      title: "Azure AI Models, Prices, and API Capabilities",
      heading: "Azure AI Models: Prices, Context Windows, and Capabilities",
      description:
        "Compare Azure AI model records, prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["Azure AI models", "Azure model list", "Azure AI model pricing"],
      search_visibility: :index,
      live_action: :provider_azure
    },
    "deepseek" => %{
      name: "DeepSeek",
      title: "DeepSeek Models, Prices, and API Capabilities",
      heading: "DeepSeek Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare DeepSeek model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["DeepSeek models", "DeepSeek model list", "DeepSeek API pricing"],
      search_visibility: :index,
      live_action: :provider_deepseek
    },
    "google" => %{
      name: "Google",
      title: "Google Gemini Models, Prices, and API Capabilities",
      heading: "Google Gemini Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare Google Gemini model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["Google Gemini models", "Gemini model list", "Gemini API pricing"],
      search_visibility: :index,
      live_action: :provider_google
    },
    "groq" => %{
      name: "Groq",
      title: "Groq Models, Prices, and API Capabilities",
      heading: "Groq Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare Groq model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["Groq models", "Groq model list", "Groq API pricing"],
      search_visibility: :index,
      live_action: :provider_groq
    },
    "mistral" => %{
      name: "Mistral AI",
      title: "Mistral AI Models, Prices, and API Capabilities",
      heading: "Mistral AI Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare Mistral AI model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["Mistral AI models", "Mistral model list", "Mistral API pricing"],
      search_visibility: :index,
      live_action: :provider_mistral
    },
    "openai" => %{
      name: "OpenAI",
      title: "OpenAI Models, Prices, and API Capabilities",
      heading: "OpenAI Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare OpenAI model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["OpenAI models", "OpenAI model list", "OpenAI API models"],
      search_visibility: :index,
      live_action: :provider_openai
    },
    "openrouter" => %{
      name: "OpenRouter",
      title: "OpenRouter Models, Prices, and API Capabilities",
      heading: "OpenRouter Models: Prices, Context Windows, and Capabilities",
      description:
        "Compare OpenRouter model records, prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["OpenRouter models", "OpenRouter model list", "OpenRouter supported models"],
      search_visibility: :index,
      live_action: :provider_openrouter
    },
    "xai" => %{
      name: "xAI",
      title: "xAI Grok Models, Prices, and API Capabilities",
      heading: "xAI Grok Models: API Prices, Context Windows, and Capabilities",
      description:
        "Compare xAI Grok model records, API prices, context windows, modalities, capabilities, and exact model IDs.",
      search_terms: ["xAI Grok models", "Grok model list", "xAI API pricing"],
      search_visibility: :index,
      live_action: :provider_xai
    }
  }

  @catalog_links [
    %{
      route: "/providers",
      label: "Browse all model providers",
      description: "See every provider and its catalog record count."
    },
    %{
      route: "/llm-models",
      label: "Browse the LLM models list",
      description: "Compare active text models across providers."
    },
    %{
      route: "/models/tool-calling",
      label: "Find tool-calling models",
      description: "Compare models with explicit tool capability metadata."
    },
    %{
      route: "/models/vision",
      label: "Browse vision models",
      description: "Find text models that accept image input."
    },
    %{
      route: "/models/long-context",
      label: "Compare long-context models",
      description: "Review models with large recorded context windows."
    },
    %{
      route: "/rankings/cheapest-llm-api",
      label: "Compare LLM API prices",
      description: "Order paid text-generation offers by recorded input price."
    }
  ]

  @spec published_ids() :: [String.t()]
  def published_ids, do: routable_ids()

  @spec routable_ids() :: [String.t()]
  def routable_ids, do: @providers |> Map.keys() |> Enum.sort()

  @spec indexable_ids() :: [String.t()]
  def indexable_ids do
    @providers
    |> Enum.filter(fn {_provider_id, content} -> content.search_visibility == :index end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @spec routes() :: [String.t()]
  def routes, do: Enum.map(routable_ids(), &path/1)

  @spec indexable_routes() :: [String.t()]
  def indexable_routes, do: Enum.map(indexable_ids(), &path/1)

  @spec navigation() :: [map()]
  def navigation do
    indexable_ids()
    |> Enum.map(fn provider_id ->
      content = Map.fetch!(@providers, provider_id)
      %{id: provider_id, name: content.name, route: path(provider_id)}
    end)
  end

  @spec path(String.t() | atom()) :: String.t()
  def path(provider_id) do
    provider_id = to_string(provider_id)
    slug = get_in(@providers, [provider_id, :slug]) || provider_id
    "/provider/#{slug}"
  end

  @spec published_path(String.t() | atom()) :: String.t() | nil
  def published_path(provider_id) do
    provider_id = to_string(provider_id)
    if Map.has_key?(@providers, provider_id), do: path(provider_id)
  end

  @spec published_path?(String.t()) :: boolean()
  def published_path?(path) when is_binary(path), do: path in routes()

  @spec indexable_path?(String.t()) :: boolean()
  def indexable_path?(path) when is_binary(path), do: path in indexable_routes()

  @spec fetch_action(atom()) :: {:ok, map()} | :error
  def fetch_action(action) when is_atom(action) do
    case Enum.find(@providers, fn {_provider_id, content} -> content.live_action == action end) do
      {provider_id, _content} -> fetch(provider_id)
      nil -> :error
    end
  end

  @spec browse_path(String.t() | atom()) :: String.t()
  def browse_path(provider_id) do
    published_path(provider_id) || ProviderDirectory.catalog_path(to_string(provider_id))
  end

  @spec fetch(String.t() | atom()) :: {:ok, map()} | :error
  def fetch(provider_id) do
    provider_id = to_string(provider_id)

    with {:ok, content} <- Map.fetch(@providers, provider_id),
         true <- Enum.any?(Catalog.list_providers(), &(to_string(&1.id) == provider_id)) do
      models =
        Catalog.list_all_models()
        |> Enum.filter(&(to_string(&1.provider) == provider_id))
        |> Enum.sort_by(&model_sort_key/1)

      active_models = Enum.filter(models, &active?/1)
      default_models = Catalog.list_models(models, Filters.new(), %{by: :newest, dir: :desc})
      latest_release_date = latest_date(models, :release_date)
      largest_context = largest_context(models)

      {:ok,
       Map.merge(content, %{
         id: provider_id,
         route: path(provider_id),
         models: models,
         model_count: length(models),
         default_models: default_models,
         default_model_count: length(default_models),
         active_count: length(active_models),
         dated_model_count: Enum.count(models, &valid_date?(Map.get(&1, :release_date))),
         evaluation_count: Enum.count(active_models, &evaluation?/1),
         latest_release_date: latest_release_date,
         largest_context: largest_context,
         last_updated: latest_date(models, :last_updated),
         summary:
           provider_summary(
             content.name,
             length(models),
             length(default_models),
             latest_release_date,
             largest_context
           ),
         related_providers: related_providers(provider_id),
         catalog_links: @catalog_links
       })}
    else
      _other -> :error
    end
  end

  @spec fetch_path(String.t()) :: {:ok, map()} | :error
  def fetch_path(path) when is_binary(path) do
    case Enum.find(routable_ids(), &(path(&1) == path)) do
      nil -> :error
      provider_id -> fetch(provider_id)
    end
  end

  @spec status(map()) :: String.t()
  def status(model) do
    cond do
      Map.get(model, :retired) == true -> "Retired"
      Map.get(model, :deprecated) == true -> "Deprecated"
      Map.get(model, :catalog_only) == true -> "Catalog only"
      true -> "Active"
    end
  end

  @spec capability_labels(map(), non_neg_integer()) :: [String.t()]
  def capability_labels(model, limit \\ 5) do
    model
    |> Map.get(:__caps, MapSet.new())
    |> Enum.map(&(&1 |> to_string() |> Phoenix.Naming.humanize()))
    |> Enum.sort()
    |> Enum.take(limit)
  end

  defp related_providers(current_id) do
    @providers
    |> Enum.reject(fn {provider_id, _content} -> provider_id == current_id end)
    |> Enum.sort_by(fn {_provider_id, content} -> content.name end)
    |> Enum.map(fn {provider_id, content} ->
      %{
        route: path(provider_id),
        label: "Browse #{content.name} models",
        description: content.description
      }
    end)
  end

  defp model_sort_key(model) do
    name = Map.get(model, :name) || Map.get(model, :model_id) || Map.get(model, :id) || ""
    model_id = Map.get(model, :model_id) || Map.get(model, :id) || ""

    case parse_date(Map.get(model, :release_date)) do
      %Date{} = date -> {0, -Date.to_gregorian_days(date), String.downcase(name), model_id}
      nil -> {1, 0, String.downcase(name), model_id}
    end
  end

  defp active?(model) do
    Map.get(model, :deprecated) != true and Map.get(model, :retired) != true
  end

  defp evaluation?(model) do
    capabilities = Map.get(model, :capabilities) || %{}
    Map.get(capabilities, :evaluate) == true or Map.get(capabilities, "evaluate") == true
  end

  defp largest_context(models) do
    models
    |> Enum.map(&Map.get(&1, :__context))
    |> Enum.filter(&(is_integer(&1) and &1 > 0))
    |> Enum.max(fn -> nil end)
  end

  defp provider_summary(
         name,
         model_count,
         default_model_count,
         latest_release_date,
         largest_context
       ) do
    release_text = latest_release_date || "an unknown date"
    context_text = Catalog.format_number(largest_context)

    "The current #{name} snapshot has #{Catalog.format_number(model_count)} records, shows #{Catalog.format_number(default_model_count)} records by default, includes releases through #{release_text}, and records a largest context window of #{context_text} tokens."
  end

  defp latest_date(models, field) do
    dates =
      models
      |> Enum.map(&Map.get(&1, field))
      |> Enum.map(&parse_date/1)
      |> Enum.reject(&is_nil/1)

    latest = if dates == [], do: nil, else: Enum.max(dates, Date)

    case latest do
      %Date{} = date -> Date.to_iso8601(date)
      nil -> nil
    end
  end

  defp valid_date?(value), do: not is_nil(parse_date(value))

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(String.slice(value, 0, 10)) do
      {:ok, date} -> date
      _other -> nil
    end
  end

  defp parse_date(_value), do: nil
end
