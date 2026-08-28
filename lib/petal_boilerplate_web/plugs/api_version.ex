defmodule PetalBoilerplateWeb.Plugs.APIVersion do
  @moduledoc """
  Advertises the stable API version and marks old history routes as deprecated.
  """

  import Plug.Conn

  @behaviour Plug

  # 2026-08-28T00:00:00Z, encoded as an HTTP Structured Field Date.
  @legacy_deprecation_date "@1787875200"

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
    |> put_resp_header("deprecation", @legacy_deprecation_date)
    |> put_resp_header(
      "link",
      ~s(<#{successor}>; rel="successor-version", </developers#versioning>; rel="deprecation")
    )
  end

  defp maybe_mark_legacy_route(conn), do: conn
end
