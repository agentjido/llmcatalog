defmodule PetalBoilerplateWeb.OgMetaTest do
  use PetalBoilerplateWeb.ConnCase

  alias PetalBoilerplate.Catalog

  describe "OpenGraph meta tags" do
    test "home page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      model_count = Catalog.format_number(Catalog.total_model_count())
      endpoint_url = PetalBoilerplateWeb.Endpoint.url()

      assert html =~ ~s(property="og:title" content="LLM Catalog")
      assert html =~ ~s(property="og:description" content="Browse and compare #{model_count})
      assert html =~ ~s(property="og:url" content="#{endpoint_url}/")
      assert html =~ ~s(property="og:type" content="website")
      assert html =~ ~s(property="og:image")
      assert html =~ ~s(rel="canonical" href="#{endpoint_url}/")

      assert html =~
               ~s(<title data-suffix=" · llmcatalog.dev">LLM Catalog · llmcatalog.dev</title>)

      assert heading_texts(html, "h1") == ["LLM Catalog"]
      assert html =~ "LLM and AI models across"
    end

    test "about page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/about")
      html = html_response(conn, 200)
      endpoint_url = PetalBoilerplateWeb.Endpoint.url()

      assert html =~ ~s(property="og:title" content="About")
      assert html =~ ~s(property="og:description" content="Learn about LLM Catalog)
      assert html =~ ~s(property="og:url" content="#{endpoint_url}/about")
    end

    test "history page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/history")
      html = html_response(conn, 200)
      endpoint_url = PetalBoilerplateWeb.Endpoint.url()

      assert html =~ ~s(property="og:title" content="Recent History")
      assert html =~ ~s(property="og:description" content="Track recent llm_db)
      assert html =~ ~s(property="og:url" content="#{endpoint_url}/history")
      assert html =~ ~s(name="robots" content="noindex, follow")
    end

    test "model detail page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/models/openai/gpt-4o")
      html = html_response(conn, 200)
      endpoint_url = PetalBoilerplateWeb.Endpoint.url()

      assert html =~ ~s(property="og:title" content="GPT-4o - openai")
      assert html =~ ~s(property="og:description")
      assert html =~ ~s(property="og:url" content="#{endpoint_url}/models/openai/gpt-4o")
      assert html =~ ~s(name="robots" content="noindex, follow")
      assert heading_texts(html, "h1") == ["GPT-4o"]
    end

    test "non-existent model returns a noindex 404 without a canonical", %{conn: conn} do
      conn = get(conn, ~p"/models/fake-provider/fake-model")
      html = html_response(conn, 404)

      assert html =~ ~s(name="robots" content="noindex, nofollow")
      refute html =~ ~s(rel="canonical")
      assert get_resp_header(conn, "x-robots-tag") == ["noindex, nofollow"]
    end

    test "Twitter card tags are present", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ ~s(name="twitter:card" content="summary_large_image")
      assert html =~ ~s(name="twitter:title")
      assert html =~ ~s(name="twitter:description")
      assert html =~ ~s(name="twitter:image")
    end

    test "query variants use a base canonical and noindex follow", %{conn: conn} do
      endpoint_url = PetalBoilerplateWeb.Endpoint.url()

      home_html =
        conn
        |> get("/?q=gpt&sort=cost_in")
        |> html_response(200)

      history_html =
        build_conn()
        |> get("/history?changed=7")
        |> html_response(200)

      assert home_html =~ ~s(rel="canonical" href="#{endpoint_url}/")
      assert home_html =~ ~s(name="robots" content="noindex, follow")
      assert history_html =~ ~s(rel="canonical" href="#{endpoint_url}/history")
      assert history_html =~ ~s(name="robots" content="noindex, follow")
    end

    test "pages emit one canonical and one Twitter card", %{conn: conn} do
      html =
        conn
        |> get("/")
        |> html_response(200)

      assert length(Regex.scan(~r/<link rel="canonical"/, html)) == 1
      assert length(Regex.scan(~r/<meta name="twitter:card"/, html)) == 1
    end
  end

  defp heading_texts(html, selector) do
    html
    |> Floki.parse_document!()
    |> Floki.find(selector)
    |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
  end
end
