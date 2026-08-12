%{
  route: "/models/tool-calling",
  page_type: :capability,
  title: "Tool-Calling LLM Models",
  description: "Browse active text-generation model identities with tool-calling metadata. Compare provider offers, context windows, token prices, and related capabilities.",
  search: %{
    primary_keyword: "tool calling LLM models",
    secondary_keywords: ["LLMs with tool calling", "function calling LLM models", "AI models for tools"],
    intent: :informational,
    audience: "Developers who build agents and applications that call functions or external tools",
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
      note: "Source for typed execution and normalized tools capability data."
    }
  ],
  methodology: %{
    name: "How the tool-calling list works",
    kind: :capability,
    summary: "The page groups active text-generation offers whose normalized capability data marks tool calling as enabled.",
    inclusion_criteria: [
      "The offer passes the active text-generation rules used by the LLM models directory.",
      "The normalized capability set includes the tools capability."
    ],
    exclusion_criteria: [
      "The list excludes records without an explicit tools capability.",
      "The list excludes catalog-only, deprecated, retired, and disallowed offers."
    ],
    rules: [
      %{
        label: "Capability meaning",
        description: "Tool calling means that source metadata marks the tools capability as enabled."
      },
      %{
        label: "Grouping",
        description: "Provider offers are grouped into conservative model identities, while provider availability remains visible."
      }
    ],
    caveats: [
      "Capability metadata does not measure tool-call accuracy, schema quality, or agent performance.",
      "Tool names, request formats, strict modes, and parallel behavior can differ by provider."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "tools-enabled",
      statement: "Every listed model identity has at least one active text offer with the tools capability.",
      evidence: :catalog_rule,
      source_ids: ["llm-db"],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "Tool-Calling LLM Models",
    description: "Browse active LLMs with tool-calling metadata. Compare providers, context windows, capabilities, and token prices.",
    related_terms: ["tool calling LLM", "function calling model", "LLM tools", "agent model"],
    og_title: "Tool-Calling LLM Models",
    og_description: "Active text-generation model identities with explicit tool-calling metadata."
  }
}
---
## Use this list for agent design

The catalog field is a useful first filter. Test the exact provider API before production use because tool schemas, strict validation, streaming, and parallel calls can differ.
