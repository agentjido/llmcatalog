%{
  route: "/models/long-context",
  page_type: :capability,
  title: "Largest Context Window LLMs",
  description: "Compare active text-generation model identities with recorded context windows of at least 128,000 tokens. Large outlier values are excluded from the ranking.",
  search: %{
    primary_keyword: "largest context window LLM",
    secondary_keywords: ["long context LLM models", "LLM context window comparison", "million token context models"],
    intent: :informational,
    audience: "Developers who compare language models for long documents, codebases, and large prompts",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-07-30",
    stale_after_days: 30,
    notes: "Approved for the initial production search test. The 10 million token outlier limit remains explicit."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llm_db",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Source for active offers and recorded model context limits."
    }
  ],
  methodology: %{
    name: "How the context ranking works",
    kind: :capability,
    summary: "The page orders active text-generation identities by their largest recorded provider context limit.",
    inclusion_criteria: [
      "The model identity has at least one offer that passes the active text-generation rules.",
      "The largest recorded context window is from 128,000 through 10 million tokens."
    ],
    exclusion_criteria: [
      "The list excludes missing and nonnumeric context values.",
      "The list excludes values above 10 million tokens as unverified outliers."
    ],
    rules: [
      %{
        label: "Context value",
        description: "A grouped identity uses the largest recorded context limit among its eligible provider offers."
      },
      %{
        label: "Ordering",
        description: "Model identities are ordered by context size, then name and model ID for stable output."
      }
    ],
    caveats: [
      "A large context window does not prove strong recall, reasoning, speed, or low cost across the full window.",
      "Providers can apply different context limits to the same model identity."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "bounded-context",
      statement: "Every listed identity has a recorded context window from 128,000 through 10 million tokens.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "Largest Context Window LLMs",
    description: "Compare long-context LLMs by recorded token limits. See providers, prices, and a clear rule for unverified outliers.",
    related_terms: ["largest context window LLM", "long context LLM", "LLM token limit", "million token context"],
    og_title: "Largest Context Window LLMs",
    og_description: "An objective catalog ranking of active LLM identities by recorded context size."
  }
}
---
## Read context limits with care

The advertised limit is only one part of long-context performance. Test retrieval quality, latency, and total prompt cost with data that matches your application.
