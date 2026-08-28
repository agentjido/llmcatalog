defmodule PetalBoilerplateWeb.APIProblem do
  @moduledoc """
  Builds stable, machine-readable API error responses.
  """

  import Plug.Conn

  alias PetalBoilerplateWeb.PublicRoutes

  @titles %{
    bad_request: "Bad request",
    not_found: "Not found",
    method_not_allowed: "Method not allowed",
    too_many_requests: "Too many requests",
    service_unavailable: "Service unavailable"
  }

  @spec respond(Plug.Conn.t(), atom(), String.t(), String.t(), keyword()) :: Plug.Conn.t()
  def respond(conn, status, code, detail, opts \\ []) do
    status_code = Plug.Conn.Status.code(status)

    body =
      %{
        type: PublicRoutes.absolute("/developers#api-errors"),
        title: Map.fetch!(@titles, status),
        status: status_code,
        detail: detail,
        instance: conn.request_path,
        code: code,
        error: code,
        resolution: Keyword.fetch!(opts, :resolution)
      }
      |> Map.merge(Keyword.get(opts, :extras, %{}))
      |> Jason.encode!()

    conn
    |> put_resp_content_type("application/problem+json", "utf-8")
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("x-robots-tag", "noindex")
    |> send_resp(status_code, body)
  end
end
