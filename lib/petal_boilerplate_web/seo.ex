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

  alias PetalBoilerplate.SEOContent
  alias PetalBoilerplate.SEOContent.Page
  alias PetalBoilerplateWeb.LandingLinks
  alias PetalBoilerplateWeb.PublicRoutes

  @default_description "Browse and compare large language models by provider, capabilities, pricing, modalities, and context windows."
  @search_indexable_paths [
    "/",
    "/about",
    "/llm-models",
    "/rankings/ai-models",
    "/rankings/cheapest-llm-api",
    "/models/vision",
    "/models/tool-calling",
    "/models/long-context",
    "/models/open-weights",
    "/models/video"
  ]

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

  @doc """
  Returns the approved sitemap paths and their last significant change date.

  Catalog build dates cover data-driven changes. A later human review date
  covers an editorial change on a published landing page.
  """
  @spec search_indexable_entries() :: [%{path: String.t(), lastmod: Date.t() | nil}]
  def search_indexable_entries do
    catalog_date = catalog_modified_on()

    Enum.map(@search_indexable_paths, fn path ->
      %{
        path: path,
        lastmod: latest_date(catalog_date, editorial_modified_on(path))
      }
    end)
  end

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
    dataset_version = Application.spec(:llm_db, :vsn) |> to_string()

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
        "creator" => %{
          "@type" => "Organization",
          "name" => "Jidoka Labs",
          "url" => "https://jidokahq.com"
        },
        "license" => "https://www.apache.org/licenses/LICENSE-2.0",
        "isAccessibleForFree" => true,
        "version" => dataset_version,
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

  @spec llm_models_list_structured_data(map(), PetalBoilerplate.SEOContent.Page.t()) ::
          [map()]
  def llm_models_list_structured_data(snapshot, page) do
    page_url = PublicRoutes.absolute("/llm-models")
    description = Page.seo_description(page)
    title = Page.seo_title(page)

    items =
      snapshot.entries
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, position} ->
        %{
          "@type" => "ListItem",
          "position" => position,
          "name" => entry.name,
          "url" => PublicRoutes.absolute(PublicRoutes.model_path(entry.representative))
        }
      end)

    collection_page =
      compact_map(%{
        "@context" => "https://schema.org",
        "@type" => "CollectionPage",
        "name" => title,
        "description" => description,
        "url" => page_url,
        "dateModified" => snapshot.last_updated,
        "keywords" => page.seo.related_terms,
        "mainEntity" => %{
          "@type" => "ItemList",
          "name" => title,
          "numberOfItems" => snapshot.model_identity_count,
          "itemListElement" => items
        }
      })

    [collection_page, breadcrumb_structured_data("/llm-models")]
  end

  @spec catalog_landing_structured_data(map(), PetalBoilerplate.SEOContent.Page.t()) ::
          [map()]
  def catalog_landing_structured_data(snapshot, page) do
    page_url = PublicRoutes.absolute(page.route)

    items =
      snapshot.sections
      |> Enum.flat_map(& &1.entries)
      |> Enum.uniq_by(fn entry ->
        {entry.representative.provider, entry.representative.model_id}
      end)
      |> Enum.take(50)
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, position} ->
        %{
          "@type" => "ListItem",
          "position" => position,
          "name" => entry.name,
          "url" => PublicRoutes.absolute(PublicRoutes.model_path(entry.representative))
        }
      end)

    collection_page =
      compact_map(%{
        "@context" => "https://schema.org",
        "@type" => "CollectionPage",
        "name" => Page.seo_title(page),
        "description" => Page.seo_description(page),
        "url" => page_url,
        "dateModified" => snapshot.last_updated,
        "keywords" => page.seo.related_terms,
        "mainEntity" => %{
          "@type" => "ItemList",
          "name" => page.title,
          "numberOfItems" => snapshot.total_count,
          "itemListElement" => items
        }
      })

    [collection_page, breadcrumb_structured_data(page.route)]
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

  defp breadcrumb_structured_data(route) do
    items =
      route
      |> LandingLinks.breadcrumbs_for()
      |> Enum.with_index(1)
      |> Enum.map(fn {item, position} ->
        %{
          "@type" => "ListItem",
          "position" => position,
          "name" => item.label,
          "item" => PublicRoutes.absolute(item.route)
        }
      end)

    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items
    }
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, "", []] end)
    |> Map.new()
  end

  defp catalog_modified_on do
    with %{meta: meta} when is_map(meta) <- LLMDB.Store.snapshot(),
         value when is_binary(value) <-
           Map.get(meta, :source_generated_at) || Map.get(meta, "source_generated_at") do
      parse_date(value)
    else
      _other -> nil
    end
  end

  defp editorial_modified_on(path) do
    case SEOContent.get_page(path) do
      %Page{review: %{reviewed_at: %Date{} = reviewed_at}} -> reviewed_at
      _other -> nil
    end
  end

  defp parse_date(value) do
    case DateTime.from_iso8601(value) do
      {:ok, date_time, _offset} ->
        DateTime.to_date(date_time)

      _other ->
        case Date.from_iso8601(value) do
          {:ok, date} -> date
          _other -> nil
        end
    end
  end

  defp latest_date(nil, nil), do: nil
  defp latest_date(%Date{} = date, nil), do: date
  defp latest_date(nil, %Date{} = date), do: date

  defp latest_date(%Date{} = left, %Date{} = right) do
    case Date.compare(left, right) do
      :lt -> right
      _other -> left
    end
  end
end
