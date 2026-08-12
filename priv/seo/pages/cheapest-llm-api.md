%{
  route: "/rankings/cheapest-llm-api",
  page_type: :price,
  title: "Cheapest LLM APIs by Token Price",
  description: "Compare active text-generation API offers by their known input and output token prices. Free, promotional, and missing prices are kept out of this paid-price list.",
  search: %{
    primary_keyword: "cheapest LLM API",
    secondary_keywords: ["cheap LLM API", "lowest cost LLM API", "LLM API pricing comparison"],
    intent: :commercial,
    audience: "Developers and technical teams that compare paid language-model API costs",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-07-30",
    stale_after_days: 30,
    notes: "Approved for the initial production search test. Keyword metrics are not confirmed."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llmdb",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Source for active provider offers, typed execution data, and token prices."
    }
  ],
  methodology: %{
    name: "How the price list works",
    kind: :price,
    summary: "The page compares provider offers with active text execution and positive input and output token prices.",
    inclusion_criteria: [
      "The offer passes the active text-generation rules used by the LLM models directory.",
      "The offer has positive numeric values for both input-token and output-token prices."
    ],
    exclusion_criteria: [
      "The list excludes zero prices because they can be free tiers, promotions, or incomplete records.",
      "The list excludes offers with a missing input or output token price."
    ],
    rules: [
      %{
        label: "Comparison unit",
        description: "The table shows catalog token prices per one million tokens."
      },
      %{
        label: "Ordering",
        description: "Offers are ordered by input price, then output price, provider ID, and model ID."
      },
      %{
        label: "Offer scope",
        description: "Each row is a provider offer. The page does not merge prices from different providers."
      }
    ],
    caveats: [
      "The lowest input price is not always the lowest total price for a specific workload.",
      "Provider discounts, cache prices, batches, subscriptions, and minimum charges can change effective cost.",
      "A low price does not measure model quality, speed, or fitness for a task."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "paid-prices-only",
      statement: "Every listed offer has positive known input and output token prices in the catalog.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "Cheapest LLM APIs by Token Price",
    description: "Compare paid LLM API offers by known input and output token prices. See clear units, providers, and data limits.",
    related_terms: ["cheapest LLM API", "cheap LLM API", "LLM API prices", "AI token cost"],
    og_title: "Cheapest LLM APIs by Token Price",
    og_description: "An objective list of paid text-generation offers ordered by known input-token price."
  }
}
---
## Use this list

Start with input price when your workload sends much more text than it receives. Check output price when responses are long. Follow each model link to inspect its complete provider record before you select an API.
