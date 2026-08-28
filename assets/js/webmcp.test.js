import assert from "node:assert/strict";
import test from "node:test";

import {registerWebMCPTools} from "./webmcp.js";

test("registers executable tools that send a current MCP request", async () => {
  const registeredTools = [];
  const requests = [];

  globalThis.document = {
    modelContext: {
      async registerTool(tool) {
        registeredTools.push(tool);
      },
    },
  };

  globalThis.fetch = async (url, options) => {
    requests.push({url, options});

    return {
      ok: true,
      status: 200,
      async json() {
        return {jsonrpc: "2.0", id: "webmcp-1", result: {isError: false}};
      },
    };
  };

  await registerWebMCPTools();

  assert.deepEqual(
    registeredTools.map((tool) => tool.name),
    ["query_models", "get_model", "list_providers"],
  );
  assert.ok(registeredTools.every((tool) => typeof tool.execute === "function"));
  assert.ok(registeredTools.every((tool) => tool.annotations.readOnlyHint));
  assert.equal(
    registeredTools[0].inputSchema.properties.provider.maxLength,
    64,
  );
  assert.equal(
    registeredTools[1].inputSchema.properties.spec.pattern,
    "^[^:\\s]+:.+$",
  );

  const abortController = new AbortController();
  await registeredTools[1].execute(
    {spec: "openai:gpt-4o"},
    {signal: abortController.signal},
  );

  assert.equal(requests.length, 1);
  assert.equal(requests[0].url, "/api/mcp");
  assert.equal(requests[0].options.headers["mcp-protocol-version"], "2026-07-28");
  assert.equal(requests[0].options.headers["mcp-method"], "tools/call");
  assert.equal(requests[0].options.headers["mcp-name"], "get_model");
  assert.equal(requests[0].options.signal, abortController.signal);

  const body = JSON.parse(requests[0].options.body);
  assert.equal(body.method, "tools/call");
  assert.equal(body.params.name, "get_model");
  assert.deepEqual(body.params.arguments, {spec: "openai:gpt-4o"});
  assert.equal(
    body.params._meta["io.modelcontextprotocol/protocolVersion"],
    "2026-07-28",
  );
  assert.deepEqual(
    body.params._meta["io.modelcontextprotocol/clientCapabilities"],
    {},
  );
});

test("does nothing when the browser does not expose WebMCP", async () => {
  globalThis.document = {};
  await registerWebMCPTools();
});
