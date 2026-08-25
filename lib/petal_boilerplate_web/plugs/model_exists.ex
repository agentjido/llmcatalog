defmodule PetalBoilerplateWeb.Plugs.ModelExists do
  @moduledoc """
  Stops unknown model routes before the LiveView returns an indexable page.
  """

  import Plug.Conn

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.ErrorController

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    provider = conn.path_params["provider"]
    model_id = conn.path_params["id"] |> List.wrap() |> Enum.join("/")

    if Catalog.get_model(provider, model_id) do
      conn
    else
      conn
      |> ErrorController.not_found(%{})
      |> halt()
    end
  end
end
