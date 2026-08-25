defmodule PetalBoilerplateWeb.APIErrorController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.APIProblem

  def not_found(conn, _params) do
    APIProblem.respond(
      conn,
      :not_found,
      "api_route_not_found",
      "This API route does not exist.",
      resolution: "Use /openapi.json or /developers to find a supported API route."
    )
  end

  def method_not_allowed(conn, _params) do
    conn
    |> put_resp_header("allow", "POST")
    |> APIProblem.respond(
      :method_not_allowed,
      "method_not_allowed",
      "The tool endpoint accepts POST requests only.",
      resolution: "Send a JSON POST request to /api/mcp."
    )
  end
end
