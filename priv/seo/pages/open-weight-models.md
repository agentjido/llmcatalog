%{
  route: "/models/open-weights",
  page_type: :directory,
  title: "Open-Weight LLM Models",
  description: "Browse active text-generation model identities whose catalog metadata marks open weights as true. The list does not claim that the models use an open-source license.",
  search: %{
    primary_keyword: "open weight LLM models",
    secondary_keywords: ["open weights models list", "open weight language models", "downloadable LLM weights"],
    intent: :informational,
    audience: "Developers and researchers who need a catalog filter for models with available weights",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-07-30",
    stale_after_days: 30,
    notes: "Approved for the initial production search test. Do not change open-weight wording to open source."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llm_db",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Source for open_weights metadata and active text-model fields."
    }
  ],
  methodology: %{
    name: "How the open-weight list works",
    kind: :directory,
    summary: "The page groups active text-generation offers whose source metadata sets open_weights to true.",
    inclusion_criteria: [
      "The offer passes the active text-generation rules used by the LLM models directory.",
      "The model extra metadata contains open_weights set to true."
    ],
    exclusion_criteria: [
      "The list excludes records where open_weights is false, missing, or not confirmed.",
      "The list excludes catalog-only, deprecated, retired, and disallowed offers."
    ],
    rules: [
      %{
        label: "Term",
        description: "Open weights describes weight availability. It does not assert an open-source software license."
      },
      %{
        label: "Grouping",
        description: "Eligible provider offers are grouped into conservative model identities."
      }
    ],
    caveats: [
      "Users must check the model license, use restrictions, hosting needs, and download source separately.",
      "Open weights do not guarantee free commercial use or complete training-data disclosure."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "open-weight-flag",
      statement: "Every listed model identity has an active text offer with open_weights set to true.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-07-30"
    },
    %{
      id: "not-license-claim",
      statement: "The page does not claim that an open-weight model has an open-source license.",
      evidence: :editorial_scope,
      source_ids: [],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "Open-Weight LLM Models List",
    description: "Browse active open-weight LLM identities with providers, context windows, capabilities, and prices. License claims are excluded.",
    related_terms: ["open weight LLM", "open weights models", "LLM weights", "self-hosted model"],
    og_title: "Open-Weight LLM Models",
    og_description: "A catalog list based on the explicit open_weights field, with a clear license warning."
  }
}
---
## Check the license

Use this page to find catalog candidates. Then check the publisher license and weight distribution source. “Open weight” is narrower than “open source.”
