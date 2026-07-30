# SEO publisher content

Search landing copy is stored in `priv/seo/pages/*.md`. Each file uses an
Elixir-map frontmatter block, a `---` separator, and a visible Markdown body.
The publisher parses and validates these files during compilation.

## Content contract

Each page defines:

- `route`, `page_type`, `title`, and `description`
- a typed `search` target with one primary keyword
- `status`: `:draft`, `:published`, or `:retired`
- a typed `review` state and freshness interval
- typed `sources` with stable IDs and checked dates
- a visible, typed `methodology`
- optional auditable `claims`
- typed `ranking_entries` for human-curated ranking pages
- typed search and social metadata in `seo`

Frontmatter accepts literal Elixir values only. Use ISO date strings such as
`"2026-07-30"`. Do not use function calls, macros, sigils, or TOML.

## Editorial rules

- Use one primary keyword per active page.
- Keep source and claim IDs stable.
- Reference only source IDs declared by the same page.
- Use `:editorial_scope` or `:editorial_judgment` for claims that do not need
  external evidence.
- Use a source ID for catalog, calculation, benchmark, and source-data claims.
- Keep methodology rules and limits visible. The HTML and Markdown responses
  render them from the same typed frontmatter.
- A ranking page must contain at least two entries. Positions must start at 1
  and be contiguous. Each entry needs a unique provider/model reference, a
  rationale, best-fit uses, strengths, limitations, and dated source evidence.
- Do not add an unexplained composite score. Store the facts and evidence that
  support each position.
- Set review status to `:approved` only with `reviewed_by` and `reviewed_at`.
- A stale or pending review does not remove a page. Use page publication status
  to control whether the publisher exposes it.

Adding a Markdown file does not create a Phoenix route. Add and test the route,
HTML rendering, Markdown rendering, structured data, internal links, and sitemap
entry as one page change.
