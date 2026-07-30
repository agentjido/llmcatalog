defmodule PetalBoilerplate.SEOContent.CatalogReference do
  @moduledoc """
  An exact provider and model record referenced by editorial content.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              provider:
                Zoi.string(description: "Catalog provider ID")
                |> Zoi.trim()
                |> Zoi.regex(~r/^[a-z0-9][a-z0-9_-]*$/),
              model_id:
                Zoi.string(description: "Exact provider model ID")
                |> Zoi.trim()
                |> Zoi.min(1)
                |> Zoi.max(300),
              display_name:
                Zoi.string(description: "Optional editorial display name")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(120)
                |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the catalog reference schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema

  @doc """
  Returns a stable key for uniqueness checks.
  """
  @spec key(t()) :: {String.t(), String.t()}
  def key(%__MODULE__{} = reference), do: {reference.provider, reference.model_id}
end
