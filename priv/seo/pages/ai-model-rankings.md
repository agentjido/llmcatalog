%{
  route: "/rankings/ai-models",
  page_type: :comparison,
  title: "AI Model Rankings by Cost, Context, and Freshness",
  description: "Compare objective AI model rankings from catalog fields: lowest paid input-token prices, largest recorded context windows, and most recently updated model records.",
  search: %{
    primary_keyword: "AI model ranking",
    secondary_keywords: ["AI model rankings", "LLM models ranking", "compare AI models"],
    intent: :informational,
    audience: "Developers and technical teams that need transparent model comparisons without a hidden score",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-07-30",
    stale_after_days: 30,
    notes: "Approved for the initial production search test. The page ranks objective catalog fields, not model quality."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llmdb",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Source for prices, context limits, model dates, providers, and capabilities."
    }
  ],
  methodology: %{
    name: "How the objective rankings work",
    kind: :comparison,
    summary: "The page shows separate rankings for measurable catalog fields and does not create an overall quality score.",
    inclusion_criteria: [
      "Each section uses active text-generation offers or grouped model identities.",
      "A record must have the specific price, context, or date field used by its section."
    ],
    exclusion_criteria: [
      "The page excludes subjective quality ranks because the catalog does not contain a common benchmark.",
      "The context section excludes values above 10 million tokens as unverified outliers."
    ],
    rules: [
      %{
        label: "Separate dimensions",
        description: "Cost, context, and catalog freshness remain separate. The page does not blend them into one score."
      },
      %{
        label: "Top ten",
        description: "Each section shows ten records ordered only by its named catalog field."
      },
      %{
        label: "No quality rank",
        description: "A position on this page does not mean that one model produces better answers than another model."
      }
    ],
    caveats: [
      "Catalog freshness is not the same as model release date or model quality.",
      "Price and context do not measure accuracy, speed, safety, or application fit."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "no-composite-score",
      statement: "The page keeps cost, context, and freshness separate and does not calculate an overall score.",
      evidence: :editorial_scope,
      source_ids: [],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "AI Model Rankings by Cost and Context",
    description: "Compare transparent AI model rankings for paid token price, context size, and catalog freshness. No hidden quality score.",
    related_terms: ["AI model ranking", "LLM model rankings", "compare AI models", "LLM leaderboard"],
    og_title: "Objective AI Model Rankings",
    og_description: "Separate rankings for known token prices, context windows, and catalog freshness."
  }
}
---
## What is ranked

This page ranks recorded fields, not answer quality. Use each section to make a shortlist. Then test the models on your own prompts and constraints.
