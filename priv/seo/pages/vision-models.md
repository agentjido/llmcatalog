%{
  route: "/models/vision",
  page_type: :capability,
  title: "Vision LLM Models",
  description: "Find active text-generation model identities that accept image input. Compare providers, context windows, known token prices, and related capabilities.",
  search: %{
    primary_keyword: "vision LLM models",
    secondary_keywords: ["multimodal LLM models", "LLMs with image input", "vision language models list"],
    intent: :informational,
    audience: "Developers who need language models that can inspect images and return text",
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
      url: "https://github.com/agentjido/llm_db",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Source for typed execution, modality, provider, context, and price data."
    }
  ],
  methodology: %{
    name: "How the vision list works",
    kind: :capability,
    summary: "The page groups active text-generation offers that list image input and text output into conservative model identities.",
    inclusion_criteria: [
      "The provider offer has explicit typed text-generation support.",
      "The input modality set includes image and the output modality set includes text."
    ],
    exclusion_criteria: [
      "The list excludes image-generation-only records that do not return text.",
      "The list excludes catalog-only, deprecated, retired, and disallowed offers."
    ],
    rules: [
      %{
        label: "Vision meaning",
        description: "Vision means that the catalog lists image as an input modality. It does not mean image generation."
      },
      %{
        label: "Grouping",
        description: "Provider offers are grouped by the conservative model identity rule used by the LLM models directory."
      }
    ],
    caveats: [
      "Image input metadata does not measure visual accuracy, supported image size, or document quality.",
      "A missing modality can mean that the source does not have a confirmed value."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "image-input",
      statement: "Every listed model identity has at least one active text offer that lists image input.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "Vision LLM Models List",
    description: "Browse active vision LLMs that accept image input and return text. Compare providers, context, capabilities, and prices.",
    related_terms: ["vision LLM models", "multimodal LLM", "image input LLM", "vision language model"],
    og_title: "Vision LLM Models",
    og_description: "A catalog-based list of active language models with image input and text output."
  }
}
---
## What vision means here

This page uses the catalog modality fields. A model is present when an active text offer accepts images and returns text. The list does not claim that every image model has the same level of visual reasoning.
