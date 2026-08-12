defmodule PetalBoilerplateWeb.Plugs.CanonicalHostTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplateWeb.Plugs.CanonicalHost

  @canonical_host "llmcatalog.dev"
  @legacy_hosts ["llmdb.xyz", "www.llmdb.xyz"]

  setup do
    previous_canonical_host = Application.get_env(:petal_boilerplate, :canonical_host)
    previous_legacy_hosts = Application.get_env(:petal_boilerplate, :legacy_hosts)

    Application.put_env(:petal_boilerplate, :canonical_host, @canonical_host)
    Application.put_env(:petal_boilerplate, :legacy_hosts, @legacy_hosts)

    on_exit(fn ->
      Application.put_env(:petal_boilerplate, :canonical_host, previous_canonical_host)
      Application.put_env(:petal_boilerplate, :legacy_hosts, previous_legacy_hosts)
    end)
  end

  test "redirects the legacy domain and preserves the path and query", %{conn: conn} do
    conn =
      conn
      |> on_host("llmdb.xyz")
      |> get("/models/vision?source=legacy")

    assert conn.status == 308

    assert get_resp_header(conn, "location") == [
             "https://llmcatalog.dev/models/vision?source=legacy"
           ]

    assert conn.halted
  end

  test "redirects the legacy home page", %{conn: conn} do
    conn =
      conn
      |> on_host("llmdb.xyz")
      |> get("/")

    assert redirected_to(conn, 308) == "https://llmcatalog.dev/"
  end

  test "redirects the legacy www host", %{conn: conn} do
    conn =
      conn
      |> on_host("www.llmdb.xyz")
      |> get("/about")

    assert redirected_to(conn, 308) == "https://llmcatalog.dev/about"
  end

  test "redirects the new www host to the apex domain", %{conn: conn} do
    conn =
      conn
      |> on_host("www.llmcatalog.dev")
      |> get("/about?source=www")

    assert redirected_to(conn, 308) == "https://llmcatalog.dev/about?source=www"
  end

  test "serves MCP POST requests on the legacy domain", %{conn: conn} do
    conn =
      conn
      |> on_host("llmdb.xyz")
      |> post("/api/mcp", %{"method" => "tools/list"})

    assert %{"tools" => tools} = json_response(conn, 200)
    assert tools != []
    assert get_resp_header(conn, "location") == []
  end

  test "redirects a GET request for the MCP path", %{conn: conn} do
    conn =
      conn
      |> on_host("llmdb.xyz")
      |> get("/api/mcp")

    assert redirected_to(conn, 308) == "https://llmcatalog.dev/api/mcp"
  end

  test "serves MCP POST requests on the canonical domain", %{conn: conn} do
    conn =
      conn
      |> on_host(@canonical_host)
      |> post("/api/mcp", %{"method" => "tools/list"})

    assert %{"tools" => tools} = json_response(conn, 200)
    assert tools != []
    assert get_resp_header(conn, "location") == []
  end

  test "serves a normal request on the canonical domain", %{conn: conn} do
    conn =
      conn
      |> on_host(@canonical_host)
      |> get("/about")

    assert html_response(conn, 200) =~ "About"
    assert get_resp_header(conn, "location") == []
  end

  test "redirects an unknown host to the configured canonical host" do
    conn =
      :get
      |> Plug.Test.conn("/about?source=unknown")
      |> on_host("untrusted.example")
      |> CanonicalHost.call(
        canonical_host: @canonical_host,
        legacy_hosts: @legacy_hosts
      )

    assert get_resp_header(conn, "location") == [
             "https://llmcatalog.dev/about?source=unknown"
           ]
  end

  test "does not redirect when no canonical host is configured" do
    conn =
      :get
      |> Plug.Test.conn("/about")
      |> on_host("llmdb.xyz")
      |> CanonicalHost.call(canonical_host: nil, legacy_hosts: @legacy_hosts)

    refute conn.halted
    assert conn.status == nil
    assert get_resp_header(conn, "location") == []
  end

  defp on_host(conn, host) do
    %{conn | host: host, scheme: :https, port: 443}
  end
end
