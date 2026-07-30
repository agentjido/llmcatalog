defmodule PetalBoilerplate.SEOContent.Source do
  @moduledoc """
  A named source that supports page data or editorial claims.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              id:
                Zoi.string(description: "Stable source ID")
                |> Zoi.regex(~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
              name:
                Zoi.string(description: "Human-readable source name")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(120),
              url: Zoi.url(description: "Canonical source URL"),
              kind:
                Zoi.enum(
                  [
                    :primary_catalog,
                    :upstream_dataset,
                    :provider_documentation,
                    :benchmark,
                    :research,
                    :editorial
                  ],
                  description: "Source evidence class"
                ),
              publisher:
                Zoi.string(description: "Source publisher")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(120)
                |> Zoi.optional(),
              retrieved_at:
                Zoi.date(description: "Date the editor checked the source", coerce: true),
              note:
                Zoi.string(description: "Scope or use note")
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
  Returns the source schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
