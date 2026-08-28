const protocolVersion = "2025-11-25";
let requestID = 0;

const toolDefinitions = [
  {
    name: "query_models",
    description:
      "Search and filter the LLM Catalog by provider, capabilities, token prices, and minimum context window.",
    inputSchema: {
      type: "object",
      properties: {
        provider: {type: "string"},
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
      idempotentHint: true,
      destructiveHint: false,
      openWorldHint: false,
    },
  },
  {
    name: "get_model",
    description:
      "Get one exact LLM Catalog record by provider:model_id, including prices, limits, capabilities, and lifecycle state.",
    inputSchema: {
      type: "object",
      required: ["spec"],
      properties: {
        spec: {type: "string", minLength: 3},
      },
      additionalProperties: false,
    },
    annotations: {
      readOnlyHint: true,
      idempotentHint: true,
      destructiveHint: false,
      openWorldHint: false,
    },
  },
  {
    name: "list_providers",
    description:
      "List every provider in the LLM Catalog with its identifier, display name, base URL, and current model count.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
    annotations: {
      readOnlyHint: true,
      idempotentHint: true,
      destructiveHint: false,
      openWorldHint: false,
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
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: `webmcp-${++requestID}`,
      method: "tools/call",
      params: {name, arguments: argumentsValue || {}},
    }),
    signal,
  });

  const payload = await response.json();

  if (!response.ok || payload.error) {
    throw new Error(payload.error?.message || `MCP request failed (${response.status})`);
  }

  return payload.result;
}

export function registerWebMCPTools() {
  const modelContext = document.modelContext || navigator.modelContext;

  if (!modelContext?.registerTool) {
    return;
  }

  for (const definition of toolDefinitions) {
    modelContext.registerTool(definition, (argumentsValue, context = {}) =>
      callMCPTool(definition.name, argumentsValue, context.signal),
    );
  }
}
