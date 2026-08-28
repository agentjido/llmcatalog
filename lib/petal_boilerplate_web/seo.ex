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
        site_name: "LLM Catalog by Jidoka Labs",
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
    "/contact",
    "/developers",
    "/llm-models",
    "/privacy",
    "/rankings/ai-models",
    "/rankings/cheapest-llm-api",
    "/rankings/free-llm-api",
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
      default_title: "LLM Catalog by Jidoka Labs",
      description: @default_description,
      title_suffix: " · llmcatalog.dev"
    )
  end

  @spec home_structured_data(non_neg_integer(), non_neg_integer()) :: [map()]
  def home_structured_data(model_count, provider_count) do
    home_url = PublicRoutes.absolute("/")
    dataset_version = Application.spec(:llm_db, :vsn) |> to_string()
    organization_id = home_url <> "#organization"
    website_id = home_url <> "#website"

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "Organization",
        "@id" => organization_id,
        "name" => "Jidoka Labs",
        "description" =>
          "Jidoka Labs builds reliable agent software and maintains the open-source LLM Catalog and llmdb projects.",
        "url" => "https://jidokahq.com",
        "contactPoint" => %{
          "@type" => "ContactPoint",
          "contactType" => "technical support",
          "url" => PublicRoutes.absolute("/contact"),
          "availableLanguage" => ["English"]
        },
        "sameAs" => [
          "https://github.com/agentjido",
          "https://www.npmjs.com/package/@agentjido/llmdb"
        ]
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "WebSite",
        "@id" => website_id,
        "name" => "LLM Catalog by Jidoka Labs",
        "alternateName" => ["LLM Catalog", "llmcatalog.dev"],
        "description" => @default_description,
        "url" => home_url,
        "publisher" => %{"@id" => organization_id}
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "Dataset",
        "name" => "LLM Catalog by Jidoka Labs",
        "description" =>
          "A catalog of #{model_count} large language models from #{provider_count} providers.",
        "url" => home_url,
        "creator" => %{"@id" => organization_id},
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
          "name" => "LLM Catalog by Jidoka Labs",
          "url" => home_url
        }
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "FAQPage",
        "name" => "LLM Catalog questions",
        "url" => home_url <> "#frequently-asked-questions",
        "mainEntity" => [
          faq_question(
            "What is LLM Catalog?",
            "LLM Catalog is a public database for comparing model providers, identifiers, capabilities, modalities, context windows, and recorded token prices."
          ),
          faq_question(
            "Can software and AI agents use LLM Catalog?",
            "Yes. The site provides Markdown pages, a versioned OpenAPI service, a read-only MCP server, and the @agentjido/llmdb npm package without an API key."
          ),
          faq_question(
            "Does a zero recorded price guarantee free model access?",
            "No. A zero value only reports the current catalog record. Provider limits, eligibility rules, and prices can change."
          ),
          faq_question(
            "Where does the catalog data come from?",
            "The open-source llmdb project normalizes public catalogs, provider APIs, and curated corrections into the records shown here."
          )
        ]
      }
    ]
  end

  @spec about_structured_data(String.t()) :: [map()]
  def about_structured_data(description) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "AboutPage",
        "name" => "About LLM Catalog",
        "description" => description,
        "url" => PublicRoutes.absolute("/about")
      }
    ]
  end

  @spec developers_structured_data(String.t()) :: [map()]
  def developers_structured_data(description) do
    package_url = "https://www.npmjs.com/package/@agentjido/llmdb"
    repository_url = "https://github.com/agentjido/llmdb/tree/main/packages/llmdb"

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "TechArticle",
        "name" => "LLM Catalog developer resources",
        "headline" => "LLM Catalog developer resources: OpenAPI, MCP, and npm",
        "description" => description,
        "url" => PublicRoutes.absolute("/developers"),
        "mainEntityOfPage" => PublicRoutes.absolute("/developers"),
        "keywords" => [
          "LLM Catalog developer resources",
          "LLM Catalog API",
          "LLM Catalog MCP server",
          "OpenAPI",
          "@agentjido/llmdb"
        ],
        "publisher" => %{"@id" => PublicRoutes.absolute("/") <> "#organization"},
        "about" => %{"@id" => PublicRoutes.absolute("/developers#llmdb-package")}
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "SoftwareSourceCode",
        "@id" => PublicRoutes.absolute("/developers#llmdb-package"),
        "name" => "@agentjido/llmdb",
        "description" =>
          "The official JavaScript and TypeScript package for local access to LLM Catalog data.",
        "url" => package_url,
        "downloadUrl" => package_url,
        "codeRepository" => repository_url,
        "programmingLanguage" => ["JavaScript", "TypeScript"],
        "runtimePlatform" => "Node.js 22.14 or later",
        "keywords" => ["LLM model data", "LLM pricing", "LLM metadata", "npm package"],
        "publisher" => %{"@id" => PublicRoutes.absolute("/") <> "#organization"},
        "sameAs" => [package_url, repository_url]
      }
    ]
  end

  @spec privacy_structured_data(String.t()) :: [map()]
  def privacy_structured_data(description) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "WebPage",
        "name" => "LLM Catalog privacy policy",
        "description" => description,
        "url" => PublicRoutes.absolute("/privacy")
      }
    ]
  end

  @spec contact_structured_data(String.t()) :: [map()]
  def contact_structured_data(description) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "ContactPage",
        "name" => "Contact LLM Catalog",
        "description" => description,
        "url" => PublicRoutes.absolute("/contact"),
        "about" => %{"@id" => PublicRoutes.absolute("/") <> "#organization"}
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
            "name" => "LLM Catalog",
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

  defp faq_question(name, answer) do
    %{
      "@type" => "Question",
      "name" => name,
      "acceptedAnswer" => %{"@type" => "Answer", "text" => answer}
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

  defp editorial_modified_on("/developers"), do: ~D[2026-08-28]

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
