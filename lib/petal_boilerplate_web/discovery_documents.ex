defmodule PetalBoilerplateWeb.DiscoveryDocuments do
  @moduledoc """
  Builds the public machine-readable discovery documents.
  """

  alias PetalBoilerplateWeb.MCP
  alias PetalBoilerplateWeb.PublicRoutes

  @skill_markdown """
  ---
  name: llm-catalog
  description: Find and compare public LLM model metadata with LLM Catalog by Jidoka Labs.
  ---

  # LLM Catalog

  Use LLM Catalog when a task needs current model identifiers, provider availability, recorded token prices, capabilities, modalities, context windows, or model metadata history.

  ## Preferred interfaces

  1. Use the MCP server at `https://llmcatalog.dev/api/mcp` for structured model lookup tools.
  2. Use `https://llmcatalog.dev/openapi.json` for the versioned public history API.
  3. Use `https://llmcatalog.dev/llms.txt` to discover Markdown pages and retrieval guidance.
  4. Use `@agentjido/llmdb` when a JavaScript or TypeScript application needs the catalog data locally.

  ## Safety and data limits

  All public interfaces are read-only and require no account or API key. Recorded prices, limits, capabilities, and availability can change. Verify important production decisions with the model provider. A recorded zero price does not guarantee permanent or unconditional free access.
  """

  @spec ard_catalog() :: map()
  def ard_catalog do
    %{
      specVersion: "1.0",
      host: %{
        displayName: "LLM Catalog by Jidoka Labs",
        identifier: "https://llmcatalog.dev",
        documentationUrl: PublicRoutes.absolute("/developers")
      },
      entries: [
        %{
          identifier: "urn:air:llmcatalog.dev:mcp:catalog",
          displayName: "LLM Catalog MCP server",
          type: "application/mcp-server-card+json",
          url: PublicRoutes.absolute("/api/mcp/server-card"),
          description: "Read-only model search, exact model lookup, and provider discovery.",
          tags: ["llm", "models", "pricing", "mcp"],
          capabilities: ["query_models", "get_model", "list_providers"],
          representativeQueries: [
            "find vision models with tool support",
            "look up one provider model",
            "list LLM providers"
          ]
        },
        %{
          identifier: "urn:air:llmcatalog.dev:api:catalog",
          displayName: "LLM Catalog API",
          type: "application/vnd.oai.openapi+json;version=3.1",
          url: PublicRoutes.absolute("/openapi.json"),
          description: "Versioned public REST API for LLM model metadata history.",
          tags: ["llm", "models", "history", "api", "openapi"]
        },
        %{
          identifier: "urn:air:llmcatalog.dev:skill:catalog",
          displayName: "LLM Catalog skill",
          type: "application/ai-skill+md",
          url: PublicRoutes.absolute("/.well-known/agent-skills/llm-catalog/SKILL.md"),
          description: "Instructions for finding and validating public LLM model metadata.",
          tags: ["llm", "models", "catalog", "skill"],
          representativeQueries: [
            "compare LLM prices and context windows",
            "find models with a required capability"
          ]
        }
      ]
    }
  end

  @spec agent_skills_index() :: map()
  def agent_skills_index do
    %{
      "$schema": "https://schemas.agentskills.io/discovery/0.2.0/schema.json",
      skills: [
        %{
          name: "llm-catalog",
          type: "skill-md",
          description:
            "Find and compare public LLM model metadata, provider availability, recorded token prices, capabilities, modalities, context windows, and model history.",
          url: "/.well-known/agent-skills/llm-catalog/SKILL.md",
          digest: "sha256:#{skill_digest()}"
        }
      ]
    }
  end

  @spec skill_markdown() :: String.t()
  def skill_markdown, do: @skill_markdown

  @spec mcp_server_card() :: map()
  def mcp_server_card do
    %{
      "$schema": "https://static.modelcontextprotocol.io/schemas/v1/server-card.schema.json",
      name: "io.github.agentjido/llmcatalog",
      title: "LLM Catalog by Jidoka Labs",
      description:
        "Public, read-only tools and resources for searching and comparing large language models.",
      version: "1.0.0",
      websiteUrl: PublicRoutes.absolute("/"),
      icons: [
        %{
          src: PublicRoutes.absolute("/favicon.ico"),
          mimeType: "image/x-icon"
        }
      ],
      repository: %{
        source: "github",
        url: "https://github.com/agentjido/llmcatalog"
      },
      remotes: [
        %{
          type: "streamable-http",
          url: PublicRoutes.absolute("/api/mcp"),
          supportedProtocolVersions: MCP.supported_protocol_versions()
        }
      ]
    }
  end

  @doc """
  Returns a broad compatibility manifest for clients that probe the
  `/.well-known/mcp.json` compatibility location.

  This document is not the MCP Server Card. The normative Server Card remains
  available at `/api/mcp/server-card` and intentionally follows its current
  schema without duplicating runtime primitive listings.
  """
  @spec mcp_compatibility_manifest() :: map()
  def mcp_compatibility_manifest do
    endpoint = PublicRoutes.absolute("/api/mcp")
    versions = MCP.supported_protocol_versions()

    %{
      name: "io.github.agentjido/llmcatalog",
      title: "LLM Catalog by Jidoka Labs",
      description:
        "Public, read-only MCP tools and resources for searching and comparing large language models.",
      version: "1.0.0",
      url: endpoint,
      serverUrl: endpoint,
      transport: "streamable-http",
      protocolVersion: hd(versions),
      supportedProtocolVersions: versions,
      serverCard: PublicRoutes.absolute("/api/mcp/server-card"),
      mcpServers: %{
        llmcatalog: %{
          type: "http",
          url: endpoint
        }
      },
      tools:
        Enum.map(
          MCP.tools(),
          &Map.take(&1, [:name, :title, :description, :inputSchema, :annotations])
        )
    }
  end

  @spec api_catalog() :: map()
  def api_catalog do
    %{
      linkset: [
        %{
          anchor: PublicRoutes.absolute("/api/v1/history/recent"),
          "service-desc": [
            %{
              href: PublicRoutes.absolute("/openapi.json"),
              type: "application/vnd.oai.openapi+json"
            }
          ],
          "service-doc": [
            %{href: PublicRoutes.absolute("/developers"), type: "text/html"}
          ]
        }
      ]
    }
  end

  defp skill_digest do
    :crypto.hash(:sha256, @skill_markdown)
    |> Base.encode16(case: :lower)
  end
end
