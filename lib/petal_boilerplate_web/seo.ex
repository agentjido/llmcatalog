defmodule PetalBoilerplateWeb.SEO do
  @moduledoc """
  Central SEO configuration and structured data builders.
  """

  use SEO,
    json_library: Jason,
    site: &__MODULE__.site_config/1,
    open_graph:
      SEO.OpenGraph.build(
        description:
          "Browse and compare large language models by provider, capabilities, pricing, modalities, and context windows.",
        site_name: "llmdb.xyz",
        locale: "en_US"
      ),
    twitter: SEO.Twitter.build(card: :summary_large_image)

  alias PetalBoilerplateWeb.PublicRoutes

  @default_description "Browse and compare large language models by provider, capabilities, pricing, modalities, and context windows."
  @search_indexable_paths ["/", "/about"]

  @spec default_description() :: String.t()
  def default_description, do: @default_description

  @spec indexing_enabled?() :: boolean()
  def indexing_enabled? do
    Application.get_env(:petal_boilerplate, :seo_indexing_enabled, false) in [
      true,
      "true",
      "1",
      "yes"
    ]
  end

  @doc """
  Returns the public HTML paths approved for search indexing.

  This list is also the source for the XML sitemap. Add a path only after
  its page has enough unique content and a clear search purpose.
  """
  @spec search_indexable_paths() :: [String.t()]
  def search_indexable_paths, do: @search_indexable_paths

  @spec search_indexable_path?(String.t()) :: boolean()
  def search_indexable_path?(path) when is_binary(path) do
    path
    |> PublicRoutes.normalize_path()
    |> then(&Enum.member?(@search_indexable_paths, &1))
  end

  def site_config(_conn) do
    SEO.Site.build(
      default_title: "LLM Model Database",
      description: @default_description,
      title_suffix: " · llmdb.xyz"
    )
  end

  @spec home_structured_data(non_neg_integer(), non_neg_integer()) :: [map()]
  def home_structured_data(model_count, provider_count) do
    home_url = PublicRoutes.absolute("/")

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "WebSite",
        "name" => "LLM Model Database",
        "alternateName" => "llmdb.xyz",
        "description" => @default_description,
        "url" => home_url
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "Dataset",
        "name" => "LLM Model Database",
        "description" =>
          "A catalog of #{model_count} large language models from #{provider_count} providers.",
        "url" => home_url,
        "keywords" => [
          "large language models",
          "LLM pricing",
          "model capabilities",
          "context windows"
        ],
        "includedInDataCatalog" => %{
          "@type" => "DataCatalog",
          "name" => "llmdb.xyz",
          "url" => home_url
        }
      }
    ]
  end

  @spec about_structured_data(String.t()) :: [map()]
  def about_structured_data(description) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "AboutPage",
        "name" => "About llmdb.xyz",
        "description" => description,
        "url" => PublicRoutes.absolute("/about")
      }
    ]
  end

  @spec history_structured_data(String.t()) :: [map()]
  def history_structured_data(description) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "CollectionPage",
        "name" => "LLM Model History",
        "description" => description,
        "url" => PublicRoutes.absolute("/history")
      }
    ]
  end

  @spec model_structured_data(map(), String.t()) :: [map()]
  def model_structured_data(model, description) do
    model_url = PublicRoutes.absolute(PublicRoutes.model_path(model))
    model_name = model.name || model.model_id
    provider_name = model.provider |> to_string() |> Phoenix.Naming.humanize()

    application =
      compact_map(%{
        "@context" => "https://schema.org",
        "@type" => "SoftwareApplication",
        "@id" => model_url <> "#model",
        "name" => model_name,
        "description" => description,
        "url" => model_url,
        "applicationCategory" => "Artificial Intelligence Model",
        "operatingSystem" => "Cloud API",
        "provider" => %{
          "@type" => "Organization",
          "name" => provider_name
        },
        "featureList" => model_features(model)
      })

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "WebPage",
        "name" => model_name,
        "description" => description,
        "url" => model_url,
        "mainEntity" => %{"@id" => application["@id"]}
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          %{
            "@type" => "ListItem",
            "position" => 1,
            "name" => "LLM Model Database",
            "item" => PublicRoutes.absolute("/")
          },
          %{
            "@type" => "ListItem",
            "position" => 2,
            "name" => model_name,
            "item" => model_url
          }
        ]
      },
      application
    ]
  end

  defp model_features(model) do
    model
    |> Map.get(:__caps, MapSet.new())
    |> Enum.map(fn capability ->
      capability
      |> to_string()
      |> Phoenix.Naming.humanize()
    end)
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, "", []] end)
    |> Map.new()
  end
end
