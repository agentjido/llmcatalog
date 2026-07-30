defmodule PetalBoilerplate.SEOContentTest do
  use ExUnit.Case, async: true

  alias PetalBoilerplate.SEOContent
  alias PetalBoilerplate.SEOContent.CatalogReference
  alias PetalBoilerplate.SEOContent.Claim
  alias PetalBoilerplate.SEOContent.Evidence
  alias PetalBoilerplate.SEOContent.FrontmatterParser
  alias PetalBoilerplate.SEOContent.Methodology
  alias PetalBoilerplate.SEOContent.MethodologyRule
  alias PetalBoilerplate.SEOContent.Page
  alias PetalBoilerplate.SEOContent.RankingEntry
  alias PetalBoilerplate.SEOContent.Review
  alias PetalBoilerplate.SEOContent.SearchMetadata
  alias PetalBoilerplate.SEOContent.SearchTarget
  alias PetalBoilerplate.SEOContent.Source

  test "loads published Markdown content with typed editorial metadata" do
    pages = SEOContent.all_pages()
    assert length(pages) == 8
    assert Enum.all?(pages, &match?(%Page{}, &1))

    page = SEOContent.get_page!("/llm-models")
    assert page.id == "llm-models"
    assert page.route == "/llm-models"
    assert page.page_type == :directory
    assert %SearchTarget{} = page.search
    assert page.search.primary_keyword == "LLM models list"
    assert page.search.intent == :informational
    assert page.status == :published

    assert %Review{
             status: :approved,
             reviewed_by: "Mike Hostetler",
             reviewed_at: ~D[2026-07-30]
           } = page.review

    assert Enum.all?(page.sources, &match?(%Source{}, &1))
    assert %Methodology{kind: :directory} = page.methodology
    assert Enum.all?(page.methodology.rules, &match?(%MethodologyRule{}, &1))
    assert Enum.all?(page.claims, &match?(%Claim{}, &1))
    assert %SearchMetadata{} = page.seo
    assert page.seo.title == "LLM Models List"
    assert page.source_path =~ "/priv/seo/pages/llm-models.md"
    assert page.markdown =~ "## What this page can answer"
    assert page.body =~ "<h2>What this page can answer</h2>"
    refute Page.stale?(page, ~D[2026-07-30])
    assert Page.stale?(page, ~D[2026-08-30])
  end

  test "looks up published content by its normalized route" do
    assert SEOContent.get_page("/llm-models/") == SEOContent.get_page!("/llm-models")

    assert SEOContent.get_page_by_keyword("  LLM MODELS LIST ") ==
             SEOContent.get_page!("/llm-models")

    assert SEOContent.get_page!("/llm-models") in SEOContent.pages_by_type(:directory)
    assert SEOContent.get_page("/missing") == nil
  end

  test "tracks a unique keyword and human approval for every landing page" do
    pages = SEOContent.all_pages()

    assert Enum.map(pages, & &1.route) == [
             "/llm-models",
             "/models/long-context",
             "/models/open-weights",
             "/models/tool-calling",
             "/models/video",
             "/models/vision",
             "/rankings/ai-models",
             "/rankings/cheapest-llm-api"
           ]

    assert pages
           |> Enum.map(&Page.primary_keyword/1)
           |> Enum.map(&String.downcase/1)
           |> Enum.uniq()
           |> length() == length(pages)

    assert Enum.all?(pages, fn page ->
             match?(
               %Review{
                 status: :approved,
                 reviewed_by: "Mike Hostetler",
                 reviewed_at: ~D[2026-07-30]
               },
               page.review
             )
           end)
  end

  test "frontmatter parser keeps the original Markdown body" do
    source = """
    %{
      route: "/example",
      title: "Example"
    }
    ---
    ## Visible copy
    """

    {attrs, markdown} = FrontmatterParser.parse("example.md", source)

    assert attrs.route == "/example"
    assert attrs.title == "Example"
    assert attrs.markdown == "## Visible copy\n"
    assert markdown == attrs.markdown
  end

  test "frontmatter parser rejects files without the separator" do
    assert_raise ArgumentError, ~r/Missing frontmatter/, fn ->
      FrontmatterParser.parse("invalid.md", "# Body only")
    end
  end

  test "frontmatter parser rejects executable expressions" do
    source = """
    %{
      route: System.get_env("UNUSED_TEST_VALUE")
    }
    ---
    Body
    """

    assert_raise ArgumentError, ~r/literal values only/, fn ->
      FrontmatterParser.parse("expression.md", source)
    end
  end

  test "page validation rejects unknown source references" do
    attrs = valid_frontmatter()
    methodology = Map.put(attrs.methodology, :source_ids, ["missing-source"])

    assert_raise ArgumentError, ~r/Unknown source IDs.*missing-source/, fn ->
      Page.build(
        "invalid-source.md",
        Map.put(attrs, :methodology, methodology),
        "<p>Visible copy</p>"
      )
    end
  end

  test "page validation rejects repeated primary and secondary keywords" do
    attrs = valid_frontmatter()
    search = Map.put(attrs.search, :secondary_keywords, ["llm MODELS list"])

    assert_raise ArgumentError, ~r/must not repeat the primary keyword/, fn ->
      Page.build(
        "duplicate-keyword.md",
        Map.put(attrs, :search, search),
        "<p>Visible copy</p>"
      )
    end
  end

  test "approved pages require a named reviewer and date" do
    attrs = valid_frontmatter()
    review = %{status: :approved, stale_after_days: 30}

    assert_raise ArgumentError, ~r/requires reviewed_by and reviewed_at/, fn ->
      Page.build(
        "invalid-review.md",
        Map.put(attrs, :review, review),
        "<p>Visible copy</p>"
      )
    end
  end

  test "ranking pages build typed entries with cited evidence" do
    page =
      ranking_frontmatter()
      |> Map.put(:ranking_entries, ranking_entries())
      |> then(&Page.build("ranking.md", &1, "<p>Visible ranking copy</p>"))

    assert page.page_type == :ranking
    assert [%RankingEntry{}, %RankingEntry{}] = page.ranking_entries
    assert %CatalogReference{} = hd(page.ranking_entries).model
    assert [%Evidence{}] = hd(page.ranking_entries).evidence
  end

  test "ranking positions must be ordered and contiguous" do
    entries =
      ranking_entries()
      |> List.update_at(1, &Map.put(&1, :position, 3))

    assert_raise ArgumentError, ~r/ordered and contiguous from 1/, fn ->
      ranking_frontmatter()
      |> Map.put(:ranking_entries, entries)
      |> then(&Page.build("invalid-ranking.md", &1, "<p>Visible ranking copy</p>"))
    end
  end

  test "ranking pages require at least two entries" do
    assert_raise ArgumentError, ~r/requires at least two ranking entries/, fn ->
      ranking_frontmatter()
      |> Map.put(:ranking_entries, [])
      |> then(&Page.build("empty-ranking.md", &1, "<p>Visible ranking copy</p>"))
    end
  end

  defp valid_frontmatter do
    source_path = Path.expand("../../priv/seo/pages/llm-models.md", __DIR__)
    {attrs, _markdown} = FrontmatterParser.parse(source_path, File.read!(source_path))
    attrs
  end

  defp ranking_frontmatter do
    attrs = valid_frontmatter()

    attrs
    |> Map.put(:page_type, :ranking)
    |> Map.put(:route, "/example-ranking")
    |> Map.put(:methodology, Map.put(attrs.methodology, :kind, :ranking))
    |> Map.put(
      :search,
      Map.put(attrs.search, :primary_keyword, "example LLM ranking")
    )
  end

  defp ranking_entries do
    [
      %{
        position: 1,
        model: %{provider: "openai", model_id: "gpt-4o"},
        label: "Best overall",
        summary:
          "The first model fits the stated use case because the cited catalog record confirms the required feature.",
        best_for: ["General application development"],
        strengths: ["Broad typed capability coverage"],
        limitations: ["The catalog record does not measure subjective output quality"],
        evidence: [
          %{
            label: "Typed execution",
            value: "Supported",
            kind: :catalog_field,
            source_id: "llm-db",
            observed_at: "2026-07-30"
          }
        ],
        claim_ids: ["typed-text-inclusion"]
      },
      %{
        position: 2,
        model: %{provider: "anthropic", model_id: "claude-sonnet-4"},
        label: "Strong alternative",
        summary:
          "The second model is a documented alternative with the required execution path and a different provider.",
        best_for: ["Teams that need provider choice"],
        strengths: ["Independent provider availability"],
        limitations: ["Provider metadata can change between catalog releases"],
        evidence: [
          %{
            label: "Catalog listing",
            value: "Active provider record",
            kind: :catalog_field,
            source_id: "llm-db",
            observed_at: "2026-07-30"
          }
        ],
        claim_ids: ["typed-text-inclusion"]
      }
    ]
  end
end
