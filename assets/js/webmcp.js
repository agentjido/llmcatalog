const protocolVersion = "2026-07-28";
let requestID = 0;

const toolDefinitions = [
  {
    name: "query_models",
    title: "Search LLM models",
    description:
      "Search and filter the LLM Catalog by provider, capabilities, token prices, and minimum context window.",
    inputSchema: {
      type: "object",
      properties: {
        provider: {
          type: "string",
          minLength: 1,
          maxLength: 64,
          pattern: "^[A-Za-z0-9][A-Za-z0-9_-]*$",
        },
        capabilities: {
          type: "object",
          properties: {
            chat: {type: "boolean"},
            embeddings: {type: "boolean"},
            reasoning: {type: "boolean"},
            tools: {type: "boolean"},
            vision: {type: "boolean"},
          },
          additionalProperties: false,
        },
        max_cost_input: {type: "number", minimum: 0},
        max_cost_output: {type: "number", minimum: 0},
        min_context: {type: "integer", minimum: 1},
        limit: {type: "integer", minimum: 1, maximum: 50, default: 20},
      },
      additionalProperties: false,
    },
    annotations: {
      readOnlyHint: true,
      untrustedContentHint: false,
    },
  },
  {
    name: "get_model",
    title: "Get one LLM model",
    description:
      "Get one exact LLM Catalog record by provider:model_id, including prices, limits, capabilities, and lifecycle state.",
    inputSchema: {
      type: "object",
      required: ["spec"],
      properties: {
        spec: {
          type: "string",
          minLength: 3,
          maxLength: 512,
          pattern: "^[^:\\s]+:.+$",
        },
      },
      additionalProperties: false,
    },
    annotations: {
      readOnlyHint: true,
      untrustedContentHint: false,
    },
  },
  {
    name: "list_providers",
    title: "List LLM providers",
    description:
      "List every provider in the LLM Catalog with its identifier, display name, base URL, and current model count.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
    annotations: {
      readOnlyHint: true,
      untrustedContentHint: false,
    },
  },
];

async function callMCPTool(name, argumentsValue, signal) {
  const response = await fetch("/api/mcp", {
    method: "POST",
    headers: {
      accept: "application/json, text/event-stream",
      "content-type": "application/json",
      "mcp-protocol-version": protocolVersion,
      "mcp-method": "tools/call",
      "mcp-name": name,
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: `webmcp-${++requestID}`,
      method: "tools/call",
      params: {
        name,
        arguments: argumentsValue || {},
        _meta: {
          "io.modelcontextprotocol/protocolVersion": protocolVersion,
          "io.modelcontextprotocol/clientCapabilities": {},
          "io.modelcontextprotocol/clientInfo": {
            name: "llmcatalog-webmcp",
            version: "1.0.0",
          },
        },
      },
    }),
    signal,
  });

  const payload = await response.json();

  if (!response.ok || payload.error) {
    throw new Error(payload.error?.message || `MCP request failed (${response.status})`);
  }

  return payload.result;
}

export async function registerWebMCPTools() {
  const modelContext = document.modelContext;

  if (!modelContext?.registerTool) {
    return;
  }

  await Promise.all(
    toolDefinitions.map((definition) =>
      modelContext.registerTool({
        ...definition,
        execute: (argumentsValue, options = {}) =>
          callMCPTool(definition.name, argumentsValue, options.signal),
      }),
    ),
  );
}
