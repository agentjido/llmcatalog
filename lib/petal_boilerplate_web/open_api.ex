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
        "version" => "1.0.0",
        "description" =>
          "Public, read-only interfaces for LLM model history and catalog lookup tools. No API key is required."
      },
      "servers" => [%{"url" => PetalBoilerplateWeb.Endpoint.url()}],
      "externalDocs" => %{
        "description" => "Developer guide",
        "url" => PublicRoutes.absolute("/developers")
      },
      "paths" => paths(),
      "components" => %{"schemas" => schemas()}
    }
  end

  defp paths do
    %{
      "/api/history/recent" => %{
        "get" => %{
          "operationId" => "listRecentModelHistory",
          "summary" => "List recent model metadata changes",
          "description" => "Returns recent changes in reverse chronological order.",
          "parameters" => [limit_parameter(50)],
          "responses" => history_responses(),
          "security" => []
        }
      },
      "/api/history/{provider}/{model_id}" => %{
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
      "/api/mcp" => %{
        "post" => %{
          "operationId" => "invokeCatalogTool",
          "summary" => "List or call catalog lookup tools",
          "description" =>
            "Accepts the documented tools/list and tools/call request shapes. This endpoint is a small tool interface, not a complete MCP protocol implementation.",
          "requestBody" => %{
            "required" => true,
            "content" => %{
              "application/json" => %{
                "schema" => %{"$ref" => "#/components/schemas/ToolRequest"},
                "examples" => %{
                  "list" => %{"value" => %{"method" => "tools/list"}},
                  "call" => %{
                    "value" => %{
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
              "description" => "Tool list or tool result.",
              "content" => %{
                "application/json" => %{
                  "schema" => %{"type" => "object", "additionalProperties" => true}
                }
              }
            },
            "400" => problem_response("Invalid tool request."),
            "405" => problem_response("Method not allowed.")
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
      "ToolRequest" => %{
        "type" => "object",
        "required" => ["method"],
        "properties" => %{
          "method" => %{"type" => "string", "enum" => ["tools/list", "tools/call"]},
          "params" => %{
            "type" => "object",
            "properties" => %{
              "name" => %{
                "type" => "string",
                "enum" => ["query_models", "get_model", "list_providers"]
              },
              "arguments" => %{"type" => "object", "additionalProperties" => true}
            }
          }
        }
      }
    }
  end

  defp history_responses do
    %{
      "200" => %{
        "description" => "Model history response.",
        "content" => %{
          "application/json" => %{
            "schema" => %{"$ref" => "#/components/schemas/HistoryResponse"}
          }
        }
      },
      "400" => problem_response("Invalid limit."),
      "404" => problem_response("Model not found."),
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
