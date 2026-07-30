defmodule PetalBoilerplate.SEOContent.RankingEntry do
  @moduledoc """
  One human-curated model entry on an editorial ranking page.

  Rankings must state who the entry is for, its strengths, its limits, and the
  cited evidence that supports its position.
  """

  alias PetalBoilerplate.SEOContent.CatalogReference
  alias PetalBoilerplate.SEOContent.Evidence

  @editorial_point_schema Zoi.string(description: "Visible editorial point")
                          |> Zoi.trim()
                          |> Zoi.min(5)
                          |> Zoi.max(300)

  @schema Zoi.struct(
            __MODULE__,
            %{
              position:
                Zoi.integer(description: "One-based rank")
                |> Zoi.min(1),
              model: CatalogReference.schema(),
              label:
                Zoi.string(description: "Visible award or rank label")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(100),
              summary:
                Zoi.string(description: "Visible editorial rationale")
                |> Zoi.trim()
                |> Zoi.min(30)
                |> Zoi.max(800),
              best_for:
                Zoi.list(@editorial_point_schema,
                  description: "Use cases that fit the model"
                )
                |> Zoi.min(1)
                |> Zoi.max(10),
              strengths:
                Zoi.list(@editorial_point_schema,
                  description: "Reasons to choose the model"
                )
                |> Zoi.min(1)
                |> Zoi.max(10),
              limitations:
                Zoi.list(@editorial_point_schema,
                  description: "Reasons the model may not fit"
                )
                |> Zoi.min(1)
                |> Zoi.max(10),
              evidence:
                Zoi.list(Evidence.schema(), description: "Cited facts that support the entry")
                |> Zoi.min(1)
                |> Zoi.max(20),
              claim_ids:
                Zoi.list(
                  Zoi.string(description: "ID of a supporting page claim"),
                  description: "Page claims used by the entry"
                )
                |> Zoi.max(20)
                |> Zoi.default([])
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the ranking entry schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
