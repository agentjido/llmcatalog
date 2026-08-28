defmodule PetalBoilerplateWeb.Plugs.RateLimit do
  @moduledoc """
  Applies the public API quota and publishes current IETF RateLimit fields.
  """

  import Plug.Conn

  alias PetalBoilerplateWeb.APIProblem
  alias PetalBoilerplateWeb.APIRateLimiter

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case APIRateLimiter.check(client_key(conn)) do
      {:allow, remaining, reset_seconds} ->
        put_rate_limit_headers(conn, remaining, reset_seconds)

      {:deny, remaining, reset_seconds} ->
        conn
        |> put_rate_limit_headers(remaining, reset_seconds)
        |> put_resp_header("retry-after", Integer.to_string(reset_seconds))
        |> APIProblem.respond(
          :too_many_requests,
          "rate_limit_exceeded",
          "The public API request quota was exceeded.",
          resolution: "Wait for Retry-After seconds before another request."
        )
        |> halt()
    end
  end

  defp put_rate_limit_headers(conn, remaining, reset_seconds) do
    {limit, window_seconds} = APIRateLimiter.policy()

    conn
    |> put_resp_header(
      "ratelimit-policy",
      ~s("public-api";q=#{limit};w=#{window_seconds})
    )
    |> put_resp_header("ratelimit", ~s("public-api";r=#{remaining};t=#{reset_seconds}))
    |> put_resp_header("ratelimit-limit", Integer.to_string(limit))
    |> put_resp_header("ratelimit-remaining", Integer.to_string(remaining))
    |> put_resp_header("ratelimit-reset", Integer.to_string(reset_seconds))
  end

  defp client_key(conn) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end
end
