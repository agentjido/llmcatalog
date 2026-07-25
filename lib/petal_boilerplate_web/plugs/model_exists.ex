defmodule PetalBoilerplateWeb.Plugs.ModelExists do
  @moduledoc """
  Stops unknown model routes before the LiveView returns an indexable page.
  """

  import Plug.Conn

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.ErrorHTML

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
      |> put_status(:not_found)
      |> put_resp_content_type("text/html", "utf-8")
      |> put_resp_header("x-robots-tag", "noindex, nofollow")
      |> send_resp(404, ErrorHTML.not_found_html())
      |> halt()
    end
  end
end
