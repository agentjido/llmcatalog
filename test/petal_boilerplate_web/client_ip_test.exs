defmodule PetalBoilerplateWeb.ClientIPTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias PetalBoilerplateWeb.ClientIP

  test "uses the Cloudflare visitor IP when Fly received the request from Cloudflare" do
    conn =
      :get
      |> conn("/")
      |> put_req_header("fly-client-ip", "173.245.48.12")
      |> put_req_header("cf-connecting-ip", "203.0.113.42")

    assert ClientIP.resolve(conn, "fly-client-ip") == "203.0.113.42"
  end

  test "supports a Cloudflare IPv6 edge and visitor" do
    conn =
      :get
      |> conn("/")
      |> put_req_header("fly-client-ip", "2606:4700::1")
      |> put_req_header("cf-connecting-ip", "2001:db8::42")

    assert ClientIP.resolve(conn, "fly-client-ip") == "2001:db8::42"
  end

  test "ignores a forged Cloudflare header on direct Fly traffic" do
    conn =
      :get
      |> conn("/")
      |> put_req_header("fly-client-ip", "192.0.2.10")
      |> put_req_header("cf-connecting-ip", "203.0.113.42")

    assert ClientIP.resolve(conn, "fly-client-ip") == "192.0.2.10"
  end

  test "uses the Fly IP when the Cloudflare visitor header is invalid" do
    conn =
      :get
      |> conn("/")
      |> put_req_header("fly-client-ip", "173.245.48.12")
      |> put_req_header("cf-connecting-ip", "not-an-ip")

    assert ClientIP.resolve(conn, "fly-client-ip") == "173.245.48.12"
  end

  test "uses the peer IP when the trusted header is missing or invalid" do
    conn =
      :get
      |> conn("/")
      |> Map.put(:remote_ip, {192, 0, 2, 22})
      |> put_req_header("fly-client-ip", "not-an-ip")

    assert ClientIP.resolve(conn, "fly-client-ip") == "192.0.2.22"
  end

  test "does not trust ambiguous visitor headers" do
    conn =
      :get
      |> conn("/")
      |> put_req_header("fly-client-ip", "173.245.48.12")
      |> Map.update!(:req_headers, fn headers ->
        [
          {"cf-connecting-ip", "203.0.113.42"},
          {"cf-connecting-ip", "203.0.113.43"}
          | headers
        ]
      end)

    assert ClientIP.resolve(conn, "fly-client-ip") == "173.245.48.12"
  end
end
