defmodule PetalBoilerplate.SEOContent.SearchTarget do
  @moduledoc """
  Search demand and reader intent for one editorial page.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              primary_keyword:
                Zoi.string(description: "One primary search phrase")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(120),
              secondary_keywords:
                Zoi.list(
                  Zoi.string(description: "Supporting search phrase")
                  |> Zoi.trim()
                  |> Zoi.min(2)
                  |> Zoi.max(120),
                  description: "Supporting search phrases"
                )
                |> Zoi.max(20)
                |> Zoi.default([]),
              intent:
                Zoi.enum([:informational, :commercial, :transactional, :navigational],
                  description: "Primary search intent"
                ),
              audience:
                Zoi.string(description: "Intended reader")
                |> Zoi.trim()
                |> Zoi.min(10)
                |> Zoi.max(240),
              locale:
                Zoi.string(description: "BCP 47 content locale")
                |> Zoi.default("en-US"),
              country:
                Zoi.string(description: "ISO 3166-1 alpha-2 research market")
                |> Zoi.regex(~r/^[A-Z]{2}$/)
                |> Zoi.default("US")
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the search target schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
