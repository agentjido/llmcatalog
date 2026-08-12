defmodule PetalBoilerplateWeb.ModelMetadataFeedback do
  @moduledoc """
  Builds links to the llm_db model metadata issue form.
  """

  alias PetalBoilerplateWeb.PublicRoutes

  @issue_url "https://github.com/agentjido/llm_db/issues/new"
  @template "model_metadata.yml"

  @form_providers %{
    "openai" => "OpenAI",
    "anthropic" => "Anthropic",
    "google" => "Google",
    "mistral" => "Mistral",
    "cohere" => "Cohere",
    "groq" => "Groq",
    "replicate" => "Replicate",
    "deepseek" => "DeepSeek",
    "xai" => "XAI"
  }

  @spec issue_url() :: String.t()
  def issue_url do
    build_url([
      {"template", @template},
      {"title", "Model metadata correction"}
    ])
  end

  @spec issue_url(map()) :: String.t()
  def issue_url(model) when is_map(model) do
    provider = model |> Map.fetch!(:provider) |> to_string()
    model_id = Map.get(model, :model_id) || Map.fetch!(model, :id)
    provider_name = provider_name(provider)
    model_page = model |> PublicRoutes.model_path() |> PublicRoutes.absolute()

    build_url([
      {"template", @template},
      {"title", "Model metadata: #{provider_name} / #{model_id}"},
      {"provider", Map.get(@form_providers, normalize_provider(provider), "Other")},
      {"model-id", model_id},
      {"additional", additional_notes(provider_name, model_page)}
    ])
  end

  defp build_url(params), do: @issue_url <> "?" <> URI.encode_query(params)

  defp provider_name(provider) do
    Map.get_lazy(@form_providers, normalize_provider(provider), fn ->
      provider
      |> String.replace(~r/[-_]+/, " ")
      |> Phoenix.Naming.humanize()
    end)
  end

  defp normalize_provider(provider) do
    provider
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "")
  end

  defp additional_notes(provider_name, model_page) do
    "Reported from llmdb.xyz\n\nModel page: #{model_page}\nCatalog provider: #{provider_name}"
  end
end
