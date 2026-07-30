defmodule PetalBoilerplate.SEOContent.MethodologyRule do
  @moduledoc """
  One visible rule used to build or interpret a data page.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              label:
                Zoi.string(description: "Short rule label")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(80),
              description:
                Zoi.string(description: "Visible rule description")
                |> Zoi.trim()
                |> Zoi.min(10)
                |> Zoi.max(400)
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the methodology rule schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema
end
