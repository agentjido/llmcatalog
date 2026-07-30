defmodule PetalBoilerplate.SEOContent.Methodology do
  @moduledoc """
  A visible and machine-readable method for a data-driven page.
  """

  alias PetalBoilerplate.SEOContent.MethodologyRule

  @schema Zoi.struct(
            __MODULE__,
            %{
              name:
                Zoi.string(description: "Visible methodology heading")
                |> Zoi.trim()
                |> Zoi.min(5)
                |> Zoi.max(100),
              kind:
                Zoi.enum([:directory, :ranking, :comparison, :price, :capability],
                  description: "Method used by the page"
                ),
              summary:
                Zoi.string(description: "Short explanation of the method")
                |> Zoi.trim()
                |> Zoi.min(20)
                |> Zoi.max(500),
              inclusion_criteria:
                Zoi.list(
                  Zoi.string(description: "Required inclusion condition")
                  |> Zoi.trim()
                  |> Zoi.min(10)
                  |> Zoi.max(300),
                  description: "Conditions that records must satisfy"
                )
                |> Zoi.min(1)
                |> Zoi.max(20),
              exclusion_criteria:
                Zoi.list(
                  Zoi.string(description: "Explicit exclusion condition")
                  |> Zoi.trim()
                  |> Zoi.min(10)
                  |> Zoi.max(300),
                  description: "Records that the page does not include"
                )
                |> Zoi.max(20)
                |> Zoi.default([]),
              rules:
                Zoi.list(MethodologyRule.schema(),
                  description: "Visible grouping, sorting, and comparison rules"
                )
                |> Zoi.min(1)
                |> Zoi.max(20),
              caveats:
                Zoi.list(
                  Zoi.string(description: "Visible data limitation")
                  |> Zoi.trim()
                  |> Zoi.min(10)
                  |> Zoi.max(400),
                  description: "Limits that affect interpretation"
                )
                |> Zoi.max(20)
                |> Zoi.default([]),
              source_ids:
                Zoi.list(
                  Zoi.string(description: "ID of a supporting page source"),
                  description: "Sources used by the methodology"
                )
                |> Zoi.min(1)
                |> Zoi.max(20)
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the methodology schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
