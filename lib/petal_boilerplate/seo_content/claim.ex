defmodule PetalBoilerplate.SEOContent.Claim do
  @moduledoc """
  A factual or editorial claim that can be audited against named sources.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              id:
                Zoi.string(description: "Stable claim ID")
                |> Zoi.regex(~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
              statement:
                Zoi.string(description: "Claim text")
                |> Zoi.trim()
                |> Zoi.min(10)
                |> Zoi.max(500),
              evidence:
                Zoi.enum(
                  [
                    :catalog_rule,
                    :source_data,
                    :calculation,
                    :benchmark,
                    :editorial_scope,
                    :editorial_judgment
                  ],
                  description: "Evidence class"
                ),
              source_ids:
                Zoi.list(
                  Zoi.string(description: "ID of a supporting page source"),
                  description: "Sources that support the claim"
                )
                |> Zoi.max(20)
                |> Zoi.default([]),
              verified_at:
                Zoi.date(description: "Date the claim was last checked", coerce: true)
                |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the claim schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
