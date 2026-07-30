defmodule PetalBoilerplate.SEOContent.Evidence do
  @moduledoc """
  One cited fact used to support an editorial ranking entry.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              label:
                Zoi.string(description: "Visible evidence label")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(100),
              value:
                Zoi.string(description: "Visible evidence value")
                |> Zoi.trim()
                |> Zoi.min(1)
                |> Zoi.max(200),
              kind:
                Zoi.enum(
                  [
                    :catalog_field,
                    :price,
                    :capability,
                    :benchmark,
                    :provider_documentation,
                    :editorial_test
                  ],
                  description: "Evidence class"
                ),
              source_id: Zoi.string(description: "ID of the supporting page source"),
              observed_at: Zoi.date(description: "Date the evidence was observed", coerce: true),
              note:
                Zoi.string(description: "Evidence scope or interpretation")
                |> Zoi.trim()
                |> Zoi.max(300)
                |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the ranking evidence schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
