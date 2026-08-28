defmodule PetalBoilerplateWeb.Plugs.APIVersion do
  @moduledoc """
  Advertises the stable API version and marks old history routes as deprecated.
  """

  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> put_resp_header("api-version", "1")
    |> maybe_mark_legacy_route()
  end

  defp maybe_mark_legacy_route(%Plug.Conn{request_path: "/api/history/" <> _rest} = conn) do
    successor = String.replace_prefix(conn.request_path, "/api/", "/api/v1/")

    conn
    |> put_resp_header("deprecation", "true")
    |> put_resp_header(
      "link",
      ~s(<#{successor}>; rel="successor-version", </developers#versioning>; rel="deprecation")
    )
  end

  defp maybe_mark_legacy_route(conn), do: conn
end
