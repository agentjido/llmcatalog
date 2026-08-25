defmodule PetalBoilerplateWeb.OpenAPIController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.OpenAPI

  def show(conn, _params) do
    conn
    |> put_resp_content_type("application/json", "utf-8")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> put_resp_header("x-robots-tag", "noindex")
    |> send_resp(200, Jason.encode!(OpenAPI.document(), pretty: true))
  end
end
