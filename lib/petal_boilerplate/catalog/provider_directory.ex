defmodule PetalBoilerplate.Catalog.ProviderDirectory do
  @moduledoc "Builds a directory from every provider and model in the catalog."

  alias PetalBoilerplate.Catalog

  @spec entries() :: [map()]
  def entries, do: entries(Catalog.list_providers(), Catalog.list_all_models())

  @spec entries([map()], [map()]) :: [map()]
  def entries(providers, models) do
    models_by_provider = Enum.group_by(models, &to_string(&1.provider))

    providers
    |> Enum.map(fn provider ->
      id = to_string(provider.id)
      provider_models = Map.get(models_by_provider, id, [])

      %{
        id: id,
        name: provider.name || Phoenix.Naming.humanize(id),
        model_count: length(provider_models),
        evaluation_count: Enum.count(provider_models, &active_evaluation?/1)
      }
    end)
    |> Enum.sort_by(&{String.downcase(&1.name), &1.id})
  end

  @spec catalog_path(String.t()) :: String.t()
  def catalog_path(provider_id) do
    "/?" <>
      URI.encode_query(%{
        "providers" => provider_id,
        "allowed_only" => "false",
        "show_deprecated" => "true"
      })
  end

  defp active_evaluation?(model) do
    capabilities = Map.get(model, :capabilities) || %{}

    Map.get(model, :deprecated) != true and Map.get(model, :retired) != true and
      (Map.get(capabilities, :evaluate) == true or Map.get(capabilities, "evaluate") == true)
  end
end
