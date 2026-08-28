defmodule PetalBoilerplateWeb.OpenAPI do
  @moduledoc """
  OpenAPI 3.1 description for the public LLM Catalog interfaces.
  """

  alias PetalBoilerplateWeb.PublicRoutes

  @spec document() :: map()
  def document do
    %{
      "openapi" => "3.1.0",
      "info" => %{
        "title" => "LLM Catalog by Jidoka Labs API",
        "version" => "1.1.0",
        "description" =>
          "Public, read-only interfaces for LLM model history and catalog lookup tools. No API key is required. Stable REST operations use a major version in the URL. Breaking REST changes require a new major path. Deprecated routes advertise a successor through Deprecation and Link response headers before removal."
      },
      "servers" => [%{"url" => PetalBoilerplateWeb.Endpoint.url()}],
      "externalDocs" => %{
        "description" => "Developer guide",
        "url" => PublicRoutes.absolute("/developers")
      },
      "x-api-versioning" => %{
        "strategy" => "URL path major version",
        "current" => "v1",
        "deprecationPolicy" => PublicRoutes.absolute("/developers#versioning")
      },
      "paths" => paths(),
      "components" => %{"schemas" => schemas()}
    }
  end

  defp paths do
    %{
      "/api/v1/history/recent" => %{
        "get" => %{
          "operationId" => "listRecentModelHistory",
          "summary" => "List recent model metadata changes",
          "description" => "Returns recent changes in reverse chronological order.",
          "parameters" => [limit_parameter(50)],
          "responses" => history_responses(),
          "security" => []
        }
      },
      "/api/v1/history/{provider}/{model_id}" => %{
        "get" => %{
          "operationId" => "getModelHistory",
          "summary" => "Get the history for one provider model",
          "description" =>
            "Returns the history for a provider and model ID. A model ID can contain additional path segments.",
          "parameters" => [
            path_parameter("provider", "Provider identifier, such as openai."),
            path_parameter("model_id", "Provider model ID. Preserve any nested path segments."),
            limit_parameter(200)
          ],
          "responses" => history_responses(),
          "security" => []
        }
      },
      "/api/history/recent" => %{
        "get" => legacy_history_operation("listRecentModelHistoryLegacy")
      },
      "/api/history/{provider}/{model_id}" => %{
        "get" =>
          legacy_history_operation("getModelHistoryLegacy")
          |> Map.put("parameters", [
            path_parameter("provider", "Provider identifier, such as openai."),
            path_parameter("model_id", "Provider model ID. Preserve nested path segments."),
            limit_parameter(200)
          ])
      },
      "/api/mcp" => %{
        "post" => %{
          "operationId" => "sendMCPMessage",
          "summary" => "Send a Model Context Protocol message",
          "description" =>
            "Stateless MCP Streamable HTTP endpoint. Supports JSON-RPC initialize, ping, tools/list, tools/call, resources/list, resources/read, and resources/templates/list for protocol versions 2025-11-25 and 2025-06-18.",
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/MCPRequest"},
                "examples" => %{
                  "initialize" => %{
                    "value" => %{
                      "jsonrpc" => "2.0",
                      "id" => 1,
                      "method" => "initialize",
                      "params" => %{
                        "protocolVersion" => "2025-11-25",
                        "capabilities" => %{},
                        "clientInfo" => %{"name" => "example", "version" => "1.0"}
                      }
                    }
                  },
                  "list" => %{
                    "value" => %{"jsonrpc" => "2.0", "id" => 2, "method" => "tools/list"}
                  },
                  "call" => %{
                    "value" => %{
                      "jsonrpc" => "2.0",
                      "id" => 3,
                      "method" => "tools/call",
                      "params" => %{
                        "name" => "get_model",
                        "arguments" => %{"spec" => "openai:gpt-4o"}
                      }
                    }
                  }
                }
              }
            }
          },
          "responses" => %{
            "200" => %{
              "description" => "JSON-RPC result or error.",
              "headers" => rate_limit_headers(),
              "content" => %{
                "application/json" => %{
                  "schema" => %{"type" => "object", "additionalProperties" => true}
                }
              }
            },
            "400" => problem_response("Invalid tool request."),
            "405" => problem_response("Method not allowed."),
            "429" => rate_limit_response()
          },
          "security" => []
        }
      }
    }
  end

  defp schemas do
    %{
      "HistoryResponse" => %{
        "type" => "object",
        "required" => ["schema_version", "events", "meta"],
        "properties" => %{
          "schema_version" => %{"type" => "integer", "minimum" => 1},
          "model_key" => %{"type" => "string"},
          "recent" => %{"type" => "boolean"},
          "events" => %{
            "type" => "array",
            "items" => %{"type" => "object", "additionalProperties" => true}
          },
          "meta" => %{"type" => "object", "additionalProperties" => true}
        }
      },
      "Problem" => %{
        "type" => "object",
        "required" => ["type", "title", "status", "detail", "instance", "code", "resolution"],
        "properties" => %{
          "type" => %{"type" => "string", "format" => "uri"},
          "title" => %{"type" => "string"},
          "status" => %{"type" => "integer"},
          "detail" => %{"type" => "string"},
          "instance" => %{"type" => "string"},
          "code" => %{"type" => "string"},
          "error" => %{"type" => "string"},
          "resolution" => %{"type" => "string"}
        }
      },
      "MCPRequest" => %{
        "type" => "object",
        "required" => ["jsonrpc", "method"],
        "properties" => %{
          "jsonrpc" => %{"type" => "string", "const" => "2.0"},
          "id" => %{"oneOf" => [%{"type" => "integer"}, %{"type" => "string"}]},
          "method" => %{
            "type" => "string",
            "enum" => [
              "initialize",
              "ping",
              "tools/list",
              "tools/call",
              "resources/list",
              "resources/read",
              "resources/templates/list",
              "notifications/initialized"
            ]
          },
          "params" => %{
            "type" => "object",
            "additionalProperties" => true
          }
        }
      }
    }
  end

  defp history_responses do
    %{
      "200" => %{
        "description" => "Model history response.",
        "headers" => rate_limit_headers(),
        "content" => %{
          "application/json" => %{
            "schema" => %{"$ref" => "#/components/schemas/HistoryResponse"}
          }
        }
      },
      "400" => problem_response("Invalid limit."),
      "404" => problem_response("Model not found."),
      "429" => rate_limit_response(),
      "503" => problem_response("History data is unavailable.")
    }
  end

  defp problem_response(description) do
    %{
      "description" => description,
      "content" => %{
        "application/problem+json" => %{
          "schema" => %{"$ref" => "#/components/schemas/Problem"}
        }
      }
    }
  end

  defp rate_limit_response do
    %{
      "description" => "The public API request quota was exceeded.",
      "headers" => Map.put(rate_limit_headers(), "Retry-After", header("Seconds to wait.")),
      "content" => %{
        "application/problem+json" => %{
          "schema" => %{"$ref" => "#/components/schemas/Problem"}
        }
      }
    }
  end

  defp rate_limit_headers do
    %{
      "RateLimit-Policy" => header("Current quota policy as an IETF structured field."),
      "RateLimit" => header("Current remaining quota and reset time."),
      "RateLimit-Limit" => header("Compatibility form of the request quota."),
      "RateLimit-Remaining" => header("Compatibility form of the remaining quota."),
      "RateLimit-Reset" => header("Seconds until the current quota window resets.")
    }
  end

  defp header(description), do: %{"description" => description, "schema" => %{"type" => "string"}}

  defp legacy_history_operation(operation_id) do
    %{
      "operationId" => operation_id,
      "summary" => "Deprecated compatibility route",
      "description" =>
        "Use the corresponding /api/v1 route. This alias sends Deprecation and successor-version Link headers. No removal date is scheduled.",
      "deprecated" => true,
      "parameters" => [limit_parameter(50)],
      "responses" => history_responses(),
      "security" => []
    }
  end

  defp path_parameter(name, description) do
    %{
      "name" => name,
      "in" => "path",
      "required" => true,
      "description" => description,
      "schema" => %{"type" => "string", "minLength" => 1}
    }
  end

  defp limit_parameter(default) do
    %{
      "name" => "limit",
      "in" => "query",
      "required" => false,
      "description" => "Maximum number of events to return.",
      "schema" => %{"type" => "integer", "minimum" => 1, "maximum" => 1_000, "default" => default}
    }
  end
end
