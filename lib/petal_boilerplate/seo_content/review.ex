defmodule PetalBoilerplate.SEOContent.Review do
  @moduledoc """
  Human review and freshness state for one editorial page.
  """

  @schema Zoi.struct(
            __MODULE__,
            %{
              status:
                Zoi.enum([:pending, :approved, :needs_update],
                  description: "Current human review state"
                )
                |> Zoi.default(:pending),
              reviewed_by:
                Zoi.string(description: "Last human reviewer")
                |> Zoi.trim()
                |> Zoi.min(2)
                |> Zoi.max(120)
                |> Zoi.optional(),
              reviewed_at:
                Zoi.date(description: "Date of the last human review", coerce: true)
                |> Zoi.optional(),
              stale_after_days:
                Zoi.integer(description: "Maximum age for time-sensitive claims")
                |> Zoi.min(1)
                |> Zoi.max(730)
                |> Zoi.default(90),
              notes:
                Zoi.string(description: "Internal review note")
                |> Zoi.trim()
                |> Zoi.max(500)
                |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc """
  Returns the review schema.
  """
  @spec schema() :: Zoi.t()
  def schema, do: @schema

  @doc """
  Returns true when the review date is older than its allowed age.

  A page without a review date is stale.
  """
  @spec stale?(t(), Date.t()) :: boolean()
  def stale?(%__MODULE__{reviewed_at: nil}, _today), do: true

  def stale?(%__MODULE__{} = review, %Date{} = today) do
    Date.diff(today, review.reviewed_at) > review.stale_after_days
  end
end
