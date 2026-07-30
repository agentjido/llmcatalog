defmodule PetalBoilerplate.SEOContent.SearchMetadata do
  @moduledoc """
  Search result and social sharing overrides for an editorial page.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              title:
                Zoi.string(description: "Search result title")
                |> Zoi.trim()
                |> Zoi.min(5)
                |> Zoi.max(60)
                |> Zoi.optional(),
              description:
                Zoi.string(description: "Search result description")
                |> Zoi.trim()
                |> Zoi.min(50)
                |> Zoi.max(160)
                |> Zoi.optional(),
              related_terms:
                Zoi.list(
                  Zoi.string(description: "Related entity or search phrase")
                  |> Zoi.trim()
                  |> Zoi.min(2)
                  |> Zoi.max(120),
                  description: "Related terms for structured data and editorial guidance"
                )
                |> Zoi.max(30)
                |> Zoi.default([]),
              og_title:
                Zoi.string(description: "Open Graph title")
                |> Zoi.trim()
                |> Zoi.min(5)
                |> Zoi.max(70)
                |> Zoi.optional(),
              og_description:
                Zoi.string(description: "Open Graph description")
                |> Zoi.trim()
                |> Zoi.min(20)
                |> Zoi.max(200)
                |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the search metadata schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
