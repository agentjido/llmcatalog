%{
  route: "/rankings/free-llm-api",
  page_type: :price,
  title: "LLM API Offers With Zero Token Prices",
  description: "Browse active text-generation provider offers whose catalog records show $0 input and output token prices. A zero price does not guarantee permanent free access, availability, or a specific usage allowance.",
  search: %{
    primary_keyword: "free LLM API",
    secondary_keywords: ["free LLM API models", "zero cost LLM API", "LLM API free tier"],
    intent: :commercial,
    audience: "Developers who want to test language-model APIs without recorded token charges",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-08-25",
    stale_after_days: 30,
    notes: "Approved with conservative language. Zero token prices are not presented as a permanent free-access guarantee."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llmdb",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-08-25",
      note: "Source for active provider offers, typed execution data, and recorded token prices."
    }
  ],
  methodology: %{
    name: "How the zero-price offer list works",
    kind: :price,
    summary: "The page lists provider offers with active text execution and numeric catalog prices of $0 for both input and output tokens.",
    inclusion_criteria: [
      "The offer passes the active text-generation rules used by the LLM models directory.",
      "The offer has numeric input-token and output-token prices that both equal zero."
    ],
    exclusion_criteria: [
      "The list excludes offers with a missing input or output token price, even when the model name or ID contains the word free.",
      "The list excludes offers when either recorded token price is greater than zero.",
      "The list excludes catalog-only, deprecated, retired, and disallowed text offers."
    ],
    rules: [
      %{
        label: "Meaning of zero",
        description: "A $0 catalog price is a recorded data value. It is not a promise of permanent free access."
      },
      %{
        label: "Comparison unit",
        description: "The table shows catalog input and output token prices per one million tokens."
      },
      %{
        label: "Offer scope",
        description: "Each row is one provider offer. The page does not transfer a zero price to offers from other providers."
      },
      %{
        label: "Ordering",
        description: "Offers are ordered by provider ID, model name, and model ID. The page does not rank model quality."
      }
    ],
    caveats: [
      "A provider can require an account and can apply quotas, rate limits, regional limits, or eligibility rules.",
      "A zero token price can be temporary, promotional, experimental, or incomplete in the source data.",
      "Request, tool, media, storage, subscription, or other charges can apply even when input and output token prices are zero.",
      "Availability and provider terms can change before the catalog receives an update. Confirm the current offer with the provider."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "zero-token-prices",
      statement: "Every listed provider offer has numeric catalog input and output token prices equal to zero.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-08-25"
    },
    %{
      id: "no-permanent-free-claim",
      statement: "The page does not claim that a listed offer provides permanent or unrestricted free access.",
      evidence: :editorial_scope,
      source_ids: [],
      verified_at: "2026-08-25"
    }
  ],
  seo: %{
    title: "Free LLM API Models With Zero Token Prices",
    description: "Find LLM API offers with recorded $0 input and output token prices. Check provider quotas, other charges, availability, and current terms.",
    related_terms: ["free LLM API", "zero cost LLM API", "LLM API free tier", "free AI API"],
    og_title: "LLM API Offers With Zero Token Prices",
    og_description: "A catalog list of active text offers with $0 input and output token prices, with clear limits on what zero price means."
  }
}
---
## Confirm the offer before use

This page uses “free” as a search term, but the list uses a narrower catalog rule: both recorded token prices must be zero. Check the provider page before use. Access rules, quotas, other charges, and prices can change.
