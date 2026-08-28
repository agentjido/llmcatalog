defmodule PetalBoilerplateWeb.MCP do
  @moduledoc """
  Defines the public Model Context Protocol tools and resources.

  All operations are public, read-only, and safe to repeat.
  """

  @latest_protocol_version "2026-07-28"
  @server_version "1.0.0"

  @overview_uri "llmcatalog://overview"
  @openapi_uri "llmcatalog://openapi"
  @providers_uri "llmcatalog://providers"

  @spec supported_protocol_versions() :: [String.t()]
  def supported_protocol_versions do
    [@latest_protocol_version | ExMCP.supported_versions()]
    |> Enum.uniq()
  end

  @spec server_info() :: map()
  def server_info do
    %{
      name: "io.github.agentjido/llmcatalog",
      title: "LLM Catalog by Jidoka Labs",
      version: @server_version,
      description: "Read-only tools and resources for comparing large language models.",
      websiteUrl: PetalBoilerplateWeb.Endpoint.url()
    }
  end

  @spec capabilities() :: map()
  def capabilities do
    %{
      tools: %{listChanged: false},
      resources: %{subscribe: false, listChanged: false}
    }
  end

  @spec instructions() :: String.t()
  def instructions do
    "Use query_models to find candidates, get_model for one exact provider:model_id, " <>
      "and list_providers to discover available providers. Verify important prices, " <>
      "limits, and availability with the model provider."
  end

  @spec initialize(map()) :: map()
  def initialize(params) do
    requested_version = Map.get(params, "protocolVersion", ExMCP.protocol_version())

    protocol_version =
      if requested_version in ExMCP.supported_versions() do
        requested_version
      else
        ExMCP.protocol_version()
      end

    %{
      protocolVersion: protocol_version,
      capabilities: capabilities(),
      serverInfo: server_info(),
      instructions: instructions()
    }
  end

  @spec tools() :: [map()]
  def tools do
    [
      %{
        name: "query_models",
        title: "Search LLM models",
        description:
          "Search and filter the LLM Catalog by provider, capabilities, token prices, and minimum context window. Returns at most 50 public catalog records.",
        inputSchema: %{
          type: "object",
          properties: %{
            provider: %{
              type: "string",
              minLength: 1,
              maxLength: 64,
              pattern: "^[A-Za-z0-9][A-Za-z0-9_-]*$",
              description: "Exact provider identifier, such as openai, anthropic, or google."
            },
            capabilities: %{
              type: "object",
              description: "Required model capabilities.",
              properties: %{
                chat: %{type: "boolean"},
                embeddings: %{type: "boolean"},
                reasoning: %{type: "boolean"},
                tools: %{type: "boolean"},
                vision: %{type: "boolean"}
              },
              additionalProperties: false
            },
            max_cost_input: %{
              type: "number",
              minimum: 0,
              description: "Maximum recorded input price per million tokens."
            },
            max_cost_output: %{
              type: "number",
              minimum: 0,
              description: "Maximum recorded output price per million tokens."
            },
            min_context: %{
              type: "integer",
              minimum: 1,
              description: "Minimum context window in tokens."
            },
            limit: %{
              type: "integer",
              minimum: 1,
              maximum: 50,
              default: 20,
              description: "Maximum number of models to return."
            }
          },
          additionalProperties: false
        },
        outputSchema: %{
          type: "object",
          required: ["count", "models"],
          properties: %{
            count: %{type: "integer", minimum: 0, maximum: 50},
            models: %{type: "array", items: %{type: "object", additionalProperties: true}}
          },
          additionalProperties: false
        },
        annotations: read_only_annotations("Search LLM models")
      },
      %{
        name: "get_model",
        title: "Get one LLM model",
        description:
          "Get one exact LLM Catalog record by provider:model_id, including capabilities, prices, limits, modalities, aliases, and lifecycle state.",
        inputSchema: %{
          type: "object",
          required: ["spec"],
          properties: %{
            spec: %{
              type: "string",
              minLength: 3,
              maxLength: 512,
              pattern: "^[^:\\s]+:.+$",
              description: "Model spec in provider:model_id form, such as openai:gpt-4o."
            }
          },
          additionalProperties: false
        },
        outputSchema: %{
          type: "object",
          required: ["model"],
          properties: %{model: %{type: "object", additionalProperties: true}},
          additionalProperties: false
        },
        annotations: read_only_annotations("Get one LLM model")
      },
      %{
        name: "list_providers",
        title: "List LLM providers",
        description:
          "List every provider in the LLM Catalog with its identifier, display name, base URL, and current model count.",
        inputSchema: %{type: "object", properties: %{}, additionalProperties: false},
        outputSchema: %{
          type: "object",
          required: ["providers"],
          properties: %{
            providers: %{
              type: "array",
              items: %{
                type: "object",
                required: ["id", "name", "base_url", "model_count"],
                properties: %{
                  id: %{type: "string"},
                  name: %{type: "string"},
                  base_url: %{type: ["string", "null"]},
                  model_count: %{type: "integer", minimum: 0}
                },
                additionalProperties: false
              }
            }
          },
          additionalProperties: false
        },
        annotations: read_only_annotations("List LLM providers")
      }
    ]
  end

  @spec call_tool(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def call_tool(name, arguments) when is_binary(name) and is_map(arguments) do
    case tool_definition(name) do
      nil ->
        {:error, "Unknown tool: #{name}"}

      tool ->
        case validate_schema(arguments, tool.inputSchema) do
          :ok -> execute_tool(name, arguments, tool.outputSchema)
          {:error, errors} -> {:ok, tool_error(validation_message(name, errors))}
        end
    end
  end

  def call_tool(name, _arguments) when is_binary(name) do
    case tool_definition(name) do
      nil -> {:error, "Unknown tool: #{name}"}
      _tool -> {:ok, tool_error("Invalid arguments for #{name}: expected a JSON object.")}
    end
  end

  defp execute_tool("query_models", arguments, output_schema) do
    limit = normalize_limit(arguments["limit"])

    structured_content =
      LLMDB.models()
      |> filter_by_provider(arguments["provider"])
      |> filter_by_capabilities(arguments["capabilities"])
      |> filter_by_cost(arguments["max_cost_input"], arguments["max_cost_output"])
      |> filter_by_context(arguments["min_context"])
      |> Enum.take(limit)
      |> Enum.map(&serialize_model/1)
      |> then(&%{count: length(&1), models: &1})

    validated_tool_result(structured_content, output_schema)
  end

  defp execute_tool("get_model", %{"spec" => spec}, output_schema) do
    case LLMDB.model(spec) do
      {:ok, model} ->
        validated_tool_result(%{model: serialize_model(model)}, output_schema)

      {:error, _reason} ->
        {:ok, tool_error("Model not found: #{spec}")}
    end
  end

  defp execute_tool("list_providers", %{}, output_schema) do
    structured_content = %{
      providers:
        LLMDB.providers()
        |> Enum.map(fn provider ->
          %{
            id: provider.id,
            name: provider.name || Phoenix.Naming.humanize(provider.id),
            base_url: provider.base_url,
            model_count: length(LLMDB.models(provider.id))
          }
        end)
    }

    validated_tool_result(structured_content, output_schema)
  end

  defp validated_tool_result(structured_content, output_schema) do
    case validate_schema(structured_content, output_schema) do
      :ok -> {:ok, tool_result(structured_content)}
      {:error, _errors} -> {:ok, tool_error("The catalog returned an invalid tool result.")}
    end
  end

  defp tool_definition(name), do: Enum.find(tools(), &(&1.name == name))

  defp validate_schema(value, schema) do
    ExMCP.Content.SchemaValidator.validate_schema(value, schema)
  end

  defp validation_message(name, errors) do
    details =
      errors
      |> Enum.take(3)
      |> Enum.map_join("; ", fn error ->
        case error.field do
          field when is_binary(field) and field != "" -> "#{field}: #{error.message}"
          _field -> error.message
        end
      end)

    "Invalid arguments for #{name}: #{details}"
  end

  @spec resources() :: [map()]
  def resources do
    [
      %{
        uri: @overview_uri,
        name: "catalog-overview",
        title: "LLM Catalog overview",
        description: "How to use the public catalog, API, Markdown pages, and model data safely.",
        mimeType: "text/markdown"
      },
      %{
        uri: @openapi_uri,
        name: "openapi",
        title: "LLM Catalog OpenAPI document",
        description: "OpenAPI 3.1 description for the versioned public history API.",
        mimeType: "application/json"
      },
      %{
        uri: @providers_uri,
        name: "providers",
        title: "LLM provider index",
        description: "Current provider identifiers, names, base URLs, and model counts.",
        mimeType: "application/json"
      }
    ]
  end

  @spec read_resource(String.t()) :: {:ok, map()} | {:error, :not_found}
  def read_resource(@overview_uri) do
    endpoint_url = PetalBoilerplateWeb.Endpoint.url()

    text = """
    # LLM Catalog by Jidoka Labs

    LLM Catalog is a public database for comparing model identifiers, providers, capabilities, context limits, modalities, and recorded prices.

    - Browse the catalog: #{endpoint_url}/
    - Read retrieval guidance: #{endpoint_url}/llms.txt
    - Read the developer guide: #{endpoint_url}/developers
    - Read the OpenAPI document: #{endpoint_url}/openapi.json
    - Install the data package: https://www.npmjs.com/package/@agentjido/llmdb

    All interfaces are public and read-only. Verify important prices, limits, and availability with the model provider before a production decision.
    """

    {:ok, resource_result(@overview_uri, "text/markdown", text)}
  end

  def read_resource(@openapi_uri) do
    text = Jason.encode!(PetalBoilerplateWeb.OpenAPI.document(), pretty: true)
    {:ok, resource_result(@openapi_uri, "application/json", text)}
  end

  def read_resource(@providers_uri) do
    {:ok, result} = call_tool("list_providers", %{})
    text = Jason.encode!(result.structuredContent, pretty: true)
    {:ok, resource_result(@providers_uri, "application/json", text)}
  end

  def read_resource(_uri), do: {:error, :not_found}

  defp read_only_annotations(title) do
    %{
      title: title,
      readOnlyHint: true,
      idempotentHint: true,
      destructiveHint: false,
      openWorldHint: false
    }
  end

  defp tool_result(structured_content) do
    %{
      content: [%{type: "text", text: Jason.encode!(structured_content, pretty: true)}],
      structuredContent: structured_content,
      isError: false
    }
  end

  defp tool_error(message) do
    %{content: [%{type: "text", text: message}], isError: true}
  end

  defp resource_result(uri, mime_type, text) do
    %{contents: [%{uri: uri, mimeType: mime_type, text: text}]}
  end

  defp normalize_limit(limit) when is_integer(limit), do: limit |> max(1) |> min(50)
  defp normalize_limit(_limit), do: 20

  defp filter_by_provider(models, nil), do: models

  defp filter_by_provider(models, provider) when is_binary(provider) do
    Enum.filter(models, &(to_string(&1.provider) == provider))
  end

  defp filter_by_provider(models, _provider), do: models

  defp filter_by_capabilities(models, capabilities) when is_map(capabilities) do
    Enum.filter(models, fn model ->
      model_capabilities = model.capabilities || %{}

      Enum.all?(capabilities, fn
        {_key, false} -> true
        {"chat", true} -> Map.get(model_capabilities, :chat) == true
        {"embeddings", true} -> Map.get(model_capabilities, :embeddings) == true
        {"reasoning", true} -> get_in(model_capabilities, [:reasoning, :enabled]) == true
        {"tools", true} -> get_in(model_capabilities, [:tools, :enabled]) == true
        {"vision", true} -> :image in (get_in(model_capabilities, [:modalities, :input]) || [])
        {_key, _value} -> false
      end)
    end)
  end

  defp filter_by_capabilities(models, _capabilities), do: models

  defp filter_by_cost(models, max_input, max_output) do
    models
    |> filter_by_cost_value([:cost, :input], max_input)
    |> filter_by_cost_value([:cost, :output], max_output)
  end

  defp filter_by_cost_value(models, _path, nil), do: models

  defp filter_by_cost_value(models, path, maximum) when is_number(maximum) do
    Enum.filter(models, fn model ->
      case get_in(model, path) do
        value when is_number(value) -> value <= maximum
        _value -> false
      end
    end)
  end

  defp filter_by_cost_value(models, _path, _maximum), do: models

  defp filter_by_context(models, nil), do: models

  defp filter_by_context(models, minimum) when is_integer(minimum) do
    Enum.filter(models, fn model ->
      case get_in(model, [:limits, :context]) do
        value when is_integer(value) -> value >= minimum
        _value -> false
      end
    end)
  end

  defp filter_by_context(models, _minimum), do: models

  defp serialize_model(model) do
    %{
      spec: "#{model.provider}:#{model.id}",
      id: model.id,
      name: model.name,
      provider: model.provider,
      family: model.family,
      aliases: model.aliases,
      tags: model.tags,
      capabilities: serialize_capabilities(model.capabilities),
      cost: model.cost,
      limits: model.limits,
      modalities: model.modalities,
      deprecated: model.deprecated
    }
  end

  defp serialize_capabilities(nil), do: %{}

  defp serialize_capabilities(capabilities) do
    %{
      chat: Map.get(capabilities, :chat, false),
      embeddings: Map.get(capabilities, :embeddings, false),
      reasoning: get_in(capabilities, [:reasoning, :enabled]) || false,
      tools: get_in(capabilities, [:tools, :enabled]) || false,
      tools_streaming: get_in(capabilities, [:tools, :streaming]) || false,
      json_native: get_in(capabilities, [:json, :native]) || false,
      input_modalities: get_in(capabilities, [:modalities, :input]) || [],
      output_modalities: get_in(capabilities, [:modalities, :output]) || []
    }
  end
end
