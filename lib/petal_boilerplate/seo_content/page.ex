defmodule PetalBoilerplate.SEOContent.Page do
  @moduledoc """
  A committed editorial page for a search landing route.

  Frontmatter contains structured search, review, and source metadata. The
  Markdown body contains the visible editorial copy.
  """

  alias PetalBoilerplate.SEOContent.Claim
  alias PetalBoilerplate.SEOContent.CatalogReference
  alias PetalBoilerplate.SEOContent.Methodology
  alias PetalBoilerplate.SEOContent.RankingEntry
  alias PetalBoilerplate.SEOContent.Review
  alias PetalBoilerplate.SEOContent.SearchMetadata
  alias PetalBoilerplate.SEOContent.SearchTarget
  alias PetalBoilerplate.SEOContent.Source

  @schema Zoi.struct(
            __MODULE__,
            %{
              id: Zoi.string(description: "Unique ID derived from the filename"),
              route: Zoi.string(description: "Canonical HTML route"),
              page_type:
                Zoi.enum([:directory, :ranking, :comparison, :price, :capability],
                  description: "Editorial page type"
                ),
              title:
                Zoi.string(description: "Visible page title")
                |> Zoi.trim()
                |> Zoi.min(5)
                |> Zoi.max(100),
              description:
                Zoi.string(description: "Visible summary and default meta description")
                |> Zoi.trim()
                |> Zoi.min(50)
                |> Zoi.max(240),
              search: SearchTarget.schema(),
              status:
                Zoi.enum([:draft, :published, :retired],
                  description: "Editorial publication state"
                )
                |> Zoi.default(:draft),
              review: Review.schema(),
              sources:
                Zoi.list(Source.schema(),
                  description: "Curated source references used by the page"
                )
                |> Zoi.min(1)
                |> Zoi.max(50),
              methodology: Methodology.schema(),
              claims:
                Zoi.list(Claim.schema(), description: "Auditable page claims")
                |> Zoi.max(100)
                |> Zoi.default([]),
              ranking_entries:
                Zoi.list(RankingEntry.schema(),
                  description: "Human-curated entries for a ranking page"
                )
                |> Zoi.max(100)
                |> Zoi.default([]),
              seo: SearchMetadata.schema(),
              body:
                Zoi.string(description: "Rendered HTML body")
                |> Zoi.min(1),
              markdown:
                Zoi.string(description: "Original Markdown body")
                |> Zoi.min(1),
              source_path: Zoi.string(description: "Source Markdown path")
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the content schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema

  @doc """
  Returns the curated search title or the visible page title.
  """
  @spec seo_title(t()) :: String.t()
  def seo_title(%__MODULE__{} = page), do: metadata_value(page.seo, :title, page.title)

  @doc """
  Returns the curated search description or the visible page description.
  """
  @spec seo_description(t()) :: String.t()
  def seo_description(%__MODULE__{} = page),
    do: metadata_value(page.seo, :description, page.description)

  @doc """
  Returns the primary keyword for the page.
  """
  @spec primary_keyword(t()) :: String.t()
  def primary_keyword(%__MODULE__{search: search}), do: search.primary_keyword

  @doc """
  Returns true when the page is published.
  """
  @spec published?(t()) :: boolean()
  def published?(%__MODULE__{status: :published}), do: true
  def published?(%__MODULE__{}), do: false

  @doc """
  Returns true when the page needs a new human review.
  """
  @spec stale?(t(), Date.t()) :: boolean()
  def stale?(%__MODULE__{review: review}, today \\ Date.utc_today()),
    do: Review.stale?(review, today)

  @doc """
  Builds and validates one page during compilation.
  """
  @spec build(String.t(), map(), String.t()) :: t()
  def build(filename, attrs, body) do
    id =
      filename
      |> Path.rootname()
      |> Path.basename()

    attrs =
      attrs
      |> Map.put(:id, id)
      |> Map.put(:body, body)
      |> Map.put(:source_path, filename)

    case Zoi.parse(@schema, attrs) do
      {:ok, page} -> validate_page!(filename, page)
      {:error, errors} -> raise ArgumentError, "Invalid SEO content #{id}: #{inspect(errors)}"
    end
  end

  defp validate_page!(filename, page) do
    validate_route!(filename, page.route)
    validate_keyword_set!(filename, page.search)
    validate_review!(filename, page.review)
    validate_source_ids!(filename, page)
    validate_methodology_kind!(filename, page)
    validate_ranking!(filename, page)
    page
  end

  defp validate_route!(filename, route) do
    case route do
      "/" ->
        :ok

      route when is_binary(route) ->
        uri = URI.parse(route)

        if String.starts_with?(route, "/") and
             not String.ends_with?(route, "/") and
             is_nil(uri.scheme) and
             is_nil(uri.host) and
             is_nil(uri.query) and
             is_nil(uri.fragment) do
          :ok
        else
          raise ArgumentError,
                "Invalid route in #{inspect(filename)}: use a path with a leading slash, " <>
                  "no trailing slash, query, or fragment"
        end

      _other ->
        raise ArgumentError, "Missing or invalid route in #{inspect(filename)}"
    end
  end

  defp validate_keyword_set!(filename, search) do
    primary = normalize_keyword(search.primary_keyword)
    secondary = Enum.map(search.secondary_keywords, &normalize_keyword/1)

    if primary in secondary do
      raise ArgumentError,
            "secondary keywords in #{inspect(filename)} must not repeat the primary keyword"
    end

    if length(secondary) != length(Enum.uniq(secondary)) do
      raise ArgumentError, "secondary keywords in #{inspect(filename)} must be unique"
    end
  end

  defp validate_review!(filename, %Review{status: :approved} = review) do
    if is_nil(review.reviewed_by) or is_nil(review.reviewed_at) do
      raise ArgumentError,
            "Approved content in #{inspect(filename)} requires reviewed_by and reviewed_at"
    end
  end

  defp validate_review!(_filename, %Review{}), do: :ok

  defp validate_source_ids!(filename, page) do
    source_ids = Enum.map(page.sources, & &1.id)

    if length(source_ids) != length(Enum.uniq(source_ids)) do
      raise ArgumentError, "Source IDs in #{inspect(filename)} must be unique"
    end

    referenced_ids =
      page.methodology.source_ids ++
        Enum.flat_map(page.claims, & &1.source_ids) ++
        Enum.flat_map(page.ranking_entries, fn entry ->
          Enum.map(entry.evidence, & &1.source_id)
        end)

    missing_ids = referenced_ids |> Enum.uniq() |> Enum.reject(&(&1 in source_ids))

    if missing_ids != [] do
      raise ArgumentError,
            "Unknown source IDs in #{inspect(filename)}: #{Enum.join(missing_ids, ", ")}"
    end

    duplicate_claim_ids? =
      page.claims
      |> Enum.map(& &1.id)
      |> then(&(length(&1) != length(Enum.uniq(&1))))

    if duplicate_claim_ids? do
      raise ArgumentError, "Claim IDs in #{inspect(filename)} must be unique"
    end

    Enum.each(page.claims, &validate_claim_sources!(filename, &1))
    validate_ranking_claim_ids!(filename, page)
  end

  defp validate_claim_sources!(_filename, %Claim{evidence: evidence})
       when evidence in [:editorial_scope, :editorial_judgment],
       do: :ok

  defp validate_claim_sources!(filename, %Claim{source_ids: []} = claim) do
    raise ArgumentError,
          "Claim #{claim.id} in #{inspect(filename)} requires at least one source ID"
  end

  defp validate_claim_sources!(_filename, %Claim{}), do: :ok

  defp validate_methodology_kind!(filename, page) do
    if page.page_type != page.methodology.kind do
      raise ArgumentError,
            "Page type and methodology kind must match in #{inspect(filename)}"
    end
  end

  defp validate_ranking!(filename, %{page_type: :ranking, ranking_entries: entries}) do
    if length(entries) < 2 do
      raise ArgumentError,
            "Ranking page #{inspect(filename)} requires at least two ranking entries"
    end

    positions = Enum.map(entries, & &1.position)
    expected_positions = Enum.to_list(1..length(entries))

    if positions != expected_positions do
      raise ArgumentError,
            "Ranking positions in #{inspect(filename)} must be ordered and contiguous from 1"
    end

    model_keys = Enum.map(entries, &CatalogReference.key(&1.model))

    if length(model_keys) != length(Enum.uniq(model_keys)) do
      raise ArgumentError,
            "Ranking model references in #{inspect(filename)} must be unique"
    end
  end

  defp validate_ranking!(_filename, %{ranking_entries: []}), do: :ok

  defp validate_ranking!(filename, _page) do
    raise ArgumentError,
          "Only a ranking page can contain ranking entries in #{inspect(filename)}"
  end

  defp validate_ranking_claim_ids!(filename, page) do
    claim_ids = MapSet.new(page.claims, & &1.id)

    missing_ids =
      page.ranking_entries
      |> Enum.flat_map(& &1.claim_ids)
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(claim_ids, &1))

    if missing_ids != [] do
      raise ArgumentError,
            "Unknown ranking claim IDs in #{inspect(filename)}: #{Enum.join(missing_ids, ", ")}"
    end
  end

  defp normalize_keyword(keyword), do: keyword |> String.trim() |> String.downcase()

  defp metadata_value(metadata, key, default) do
    case Map.get(metadata, key) do
      value when is_binary(value) and value != "" -> value
      _other -> default
    end
  end
end
