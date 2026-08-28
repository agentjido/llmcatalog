defmodule PetalBoilerplateWeb.RateLimitTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  setup do
    previous = Application.get_env(:petal_boilerplate, :api_rate_limit)
    previous_header = Application.get_env(:petal_boilerplate, :trusted_client_ip_header)
    Application.put_env(:petal_boilerplate, :api_rate_limit, limit: 1, window_seconds: 60)

    on_exit(fn ->
      Application.put_env(:petal_boilerplate, :api_rate_limit, previous)

      if previous_header do
        Application.put_env(:petal_boilerplate, :trusted_client_ip_header, previous_header)
      else
        Application.delete_env(:petal_boilerplate, :trusted_client_ip_header)
      end
    end)

    :ok
  end

  test "returns problem JSON and backoff fields after the quota", %{conn: conn} do
    first = conn |> with_remote_ip({203, 0, 113, 91}) |> get("/openapi.json")
    assert response(first, 200)
    assert get_resp_header(first, "ratelimit-policy") == [~s("public-api";q=1;w=60)]

    second = build_conn() |> with_remote_ip({203, 0, 113, 91}) |> get("/openapi.json")
    body = json_response(second, 429)

    assert body["code"] == "rate_limit_exceeded"
    assert get_resp_header(second, "retry-after") != []
    assert get_resp_header(second, "ratelimit") != []
    assert get_resp_header(second, "content-type") |> hd() =~ "application/problem+json"
  end

  test "uses a valid Fly client IP when the trusted header is enabled", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :trusted_client_ip_header, "fly-client-ip")

    first =
      conn
      |> with_remote_ip({192, 0, 2, 10})
      |> put_req_header("fly-client-ip", "203.0.113.10")
      |> get("/openapi.json")

    second =
      build_conn()
      |> with_remote_ip({192, 0, 2, 10})
      |> put_req_header("fly-client-ip", "203.0.113.11")
      |> get("/openapi.json")

    assert response(first, 200)
    assert response(second, 200)
  end

  test "rejects an invalid trusted header and falls back to the peer IP", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :trusted_client_ip_header, "fly-client-ip")

    first =
      conn
      |> with_remote_ip({192, 0, 2, 11})
      |> put_req_header("fly-client-ip", "not-an-ip")
      |> get("/openapi.json")

    second =
      build_conn()
      |> with_remote_ip({192, 0, 2, 11})
      |> get("/openapi.json")

    assert response(first, 200)
    assert json_response(second, 429)["code"] == "rate_limit_exceeded"
  end

  defp with_remote_ip(conn, remote_ip), do: %{conn | remote_ip: remote_ip}
end
