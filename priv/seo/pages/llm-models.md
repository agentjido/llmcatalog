%{
  route: "/llm-models",
  page_type: :directory,
  title: "LLM Models List",
  description: "Browse active large language models with known text-generation support. Compare provider offers, context windows, capabilities, and token prices.",
  search: %{
    primary_keyword: "LLM models list",
    secondary_keywords: [
      "large language models list",
      "list of LLM models",
      "LLM model database",
      "AI models list"
    ],
    intent: :informational,
    audience: "Developers and technical teams that need a current directory of text-generation models",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-07-30",
    stale_after_days: 30,
    notes: "Approved for production as the main LLM model directory hub."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llm_db",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Primary source for model records, typed execution data, prices, and capabilities."
    },
    %{
      id: "models-dev",
      name: "models.dev",
      url: "https://models.dev",
      kind: :upstream_dataset,
      publisher: "models.dev",
      retrieved_at: "2026-07-30",
      note: "One upstream source used by the llm_db catalog."
    }
  ],
  methodology: %{
    name: "How this LLM list works",
    kind: :directory,
    summary: "The page builds a conservative directory from active provider offers with explicit typed text-generation support.",
    inclusion_criteria: [
      "The provider offer is allowed and is not catalog-only, deprecated, or retired.",
      "The execution metadata explicitly marks text generation as supported.",
      "The input and output modality sets both include text."
    ],
    exclusion_criteria: [
      "The list excludes catalog-only, deprecated, and retired provider offers.",
      "The list excludes offers without explicit typed text execution support.",
      "The list excludes records that do not support both text input and text output."
    ],
    rules: [
      %{
        label: "Grouping",
        description: "Provider offers are grouped by a conservative normalized model ID and by explicit aliases from the model database. A vendor prefix is removed only when the remaining ID is specific and agrees with the model name."
      },
      %{
        label: "Context limits",
        description: "The context value is the largest recorded provider limit for the grouped model identity."
      },
      %{
        label: "Token price",
        description: "The displayed price pair comes from the offer with the lowest known input-token price."
      },
      %{
        label: "Ordering",
        description: "Models are ordered by the latest valid metadata date, then by name and model ID for stable output."
      }
    ],
    caveats: [
      "This page is a directory. It does not rank model quality or benchmark performance.",
      "A missing price or capability means that the catalog does not have a confirmed value. It does not prove that the model lacks that feature.",
      "Provider metadata changes often and can become stale between catalog releases."
    ],
    source_ids: ["llm-db", "models-dev"]
  },
  claims: [
    %{
      id: "typed-text-inclusion",
      statement: "Every included offer has explicit typed text-generation support and text input and output modalities.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-07-30"
    },
    %{
      id: "directory-not-ranking",
      statement: "The page is a model directory and does not claim to rank model quality.",
      evidence: :editorial_scope,
      source_ids: [],
      verified_at: "2026-07-30"
    },
    %{
      id: "metadata-can-be-incomplete",
      statement: "A missing catalog value does not prove that a provider or model lacks the related feature.",
      evidence: :editorial_judgment,
      source_ids: ["llm-db", "models-dev"],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "LLM Models List",
    description: "Browse active LLM models and compare provider offers, context windows, capabilities, and token prices.",
    related_terms: [
      "LLM models list",
      "large language models list",
      "list of LLM models",
      "LLM model database"
    ],
    og_title: "LLM Models List",
    og_description: "A current list of active text-generation models with provider, context, capability, and price data."
  }
}
---
## What this page can answer

Use this page to find active LLM model IDs, see which providers offer each model, and compare known context windows, capabilities, and token prices. Follow a model link for the complete provider record.
