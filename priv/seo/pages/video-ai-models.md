%{
  route: "/models/video",
  page_type: :capability,
  title: "Video AI Models for Input and Generation",
  description: "Browse video AI model identities in two separate lists: models that accept video input and models that generate video output. The page does not mix these different tasks.",
  search: %{
    primary_keyword: "video AI models",
    secondary_keywords: ["AI video models list", "video understanding models", "video generation models"],
    intent: :informational,
    audience: "Developers and creators who compare models for video understanding or video generation",
    locale: "en-US",
    country: "US"
  },
  status: :published,
  review: %{
    status: :approved,
    reviewed_by: "Mike Hostetler",
    reviewed_at: "2026-07-30",
    stale_after_days: 30,
    notes: "Approved for the initial production search test. Saved keyword research shows low demand."
  },
  sources: [
    %{
      id: "llm-db",
      name: "llm_db",
      url: "https://github.com/agentjido/llmdb",
      kind: :primary_catalog,
      publisher: "AgentJido",
      retrieved_at: "2026-07-30",
      note: "Source for provider records and video input and output modality fields."
    }
  ],
  methodology: %{
    name: "How the video lists work",
    kind: :capability,
    summary: "The page uses explicit modality fields and keeps video understanding separate from video generation.",
    inclusion_criteria: [
      "The provider record is allowed and is not deprecated or retired.",
      "The input section requires video input, and the output section requires video output."
    ],
    exclusion_criteria: [
      "The page does not infer video support from a model name or marketing description.",
      "A model is not placed in both sections unless its metadata supports both directions."
    ],
    rules: [
      %{
        label: "Input section",
        description: "Video input means that a model can receive video according to its catalog modality data."
      },
      %{
        label: "Output section",
        description: "Video output means that a model can generate video according to its catalog modality data."
      },
      %{
        label: "Grouping",
        description: "Provider records are grouped into conservative model identities within each section."
      }
    ],
    caveats: [
      "The catalog fields do not measure duration, resolution, frame rate, latency, or generation quality.",
      "Some catalog-only records can describe a valid model even when llm_db does not provide a typed execution adapter."
    ],
    source_ids: ["llm-db"]
  },
  claims: [
    %{
      id: "separate-video-directions",
      statement: "The page reports video input and video output in separate sections.",
      evidence: :editorial_scope,
      source_ids: [],
      verified_at: "2026-07-30"
    }
  ],
  seo: %{
    title: "Video AI Models List",
    description: "Compare video AI models in separate input and generation lists. See providers, model IDs, context, prices, and limits.",
    related_terms: ["video AI models", "video understanding model", "video generation model", "multimodal video AI"],
    og_title: "Video AI Models",
    og_description: "Separate catalog lists for models with video input and models with video output."
  }
}
---
## Select the correct video task

Use the input list for understanding, analysis, or extraction from video. Use the output list for video generation. Check the provider record for exact limits and API support.
