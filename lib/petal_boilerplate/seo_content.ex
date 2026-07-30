defmodule PetalBoilerplate.SEOContent do
  @moduledoc """
  Compile-time registry for committed search landing content.

  Markdown files under `priv/seo/pages/` provide the visible copy and
  Elixir-map frontmatter provides structured editorial metadata.
  """

  alias PetalBoilerplate.SEOContent.Page

  Code.ensure_compiled!(PetalBoilerplate.SEOContent.FrontmatterParser)

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:petal_boilerplate, "priv/seo/pages/**/*.md"),
    as: :pages,
    parser: PetalBoilerplate.SEOContent.FrontmatterParser

  @pages Enum.sort_by(@pages, & &1.route)
  @published_pages Enum.filter(@pages, &Page.published?/1)
  @route_groups Enum.group_by(@pages, & &1.route)
  @id_groups Enum.group_by(@pages, & &1.id)

  @keyword_groups @pages
                  |> Enum.reject(&(&1.status == :retired))
                  |> Enum.group_by(fn page ->
                    page
                    |> Page.primary_keyword()
                    |> String.trim()
                    |> String.downcase()
                  end)

  for {route, pages} <- @route_groups, length(pages) > 1 do
    source_paths = Enum.map_join(pages, ", ", & &1.source_path)
    raise ArgumentError, "Duplicate SEO content route #{route}: #{source_paths}"
  end

  for {id, pages} <- @id_groups, length(pages) > 1 do
    source_paths = Enum.map_join(pages, ", ", & &1.source_path)
    raise ArgumentError, "Duplicate SEO content ID #{id}: #{source_paths}"
  end

  for {keyword, pages} <- @keyword_groups, length(pages) > 1 do
    routes = Enum.map_join(pages, ", ", & &1.route)

    raise ArgumentError,
          "Primary keyword #{inspect(keyword)} targets more than one SEO page: #{routes}"
  end

  @published_by_route Map.new(@published_pages, &{&1.route, &1})
  @published_by_keyword Map.new(@published_pages, fn page ->
                          keyword =
                            page
                            |> Page.primary_keyword()
                            |> String.trim()
                            |> String.downcase()

                          {keyword, page}
                        end)
  @published_by_type Enum.group_by(@published_pages, & &1.page_type)

  @doc """
  Returns all published editorial pages.
  """
  @spec all_pages() :: [Page.t()]
  def all_pages, do: @published_pages

  @doc """
  Returns all editorial pages, including drafts and retired pages.
  """
  @spec all_pages_including_unpublished() :: [Page.t()]
  def all_pages_including_unpublished, do: @pages

  @doc """
  Returns published content for a canonical route.
  """
  @spec get_page(String.t()) :: Page.t() | nil
  def get_page(route) when is_binary(route),
    do: Map.get(@published_by_route, normalize_route(route))

  @doc """
  Returns published content for a canonical route or raises.
  """
  @spec get_page!(String.t()) :: Page.t()
  def get_page!(route) when is_binary(route) do
    get_page(route) ||
      raise ArgumentError, "Published SEO content for route #{inspect(route)} was not found"
  end

  @doc """
  Returns published content for a primary keyword.
  """
  @spec get_page_by_keyword(String.t()) :: Page.t() | nil
  def get_page_by_keyword(keyword) when is_binary(keyword) do
    normalized = keyword |> String.trim() |> String.downcase()
    Map.get(@published_by_keyword, normalized)
  end

  @doc """
  Returns published pages of one editorial type.
  """
  @spec pages_by_type(atom()) :: [Page.t()]
  def pages_by_type(page_type) when is_atom(page_type),
    do: Map.get(@published_by_type, page_type, [])

  defp normalize_route("/"), do: "/"
  defp normalize_route(route), do: String.trim_trailing(route, "/")
end
