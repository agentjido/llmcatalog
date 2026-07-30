defmodule PetalBoilerplateWeb.StructuredDataTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  test "home page emits WebSite and Dataset JSON-LD", %{conn: conn} do
    html =
      conn
      |> get("/")
      |> html_response(200)

    schemas = json_ld(html)

    assert Enum.map(schemas, & &1["@type"]) == ["WebSite", "Dataset"]
    assert Enum.all?(schemas, &(&1["url"] == PetalBoilerplateWeb.Endpoint.url() <> "/"))
  end

  test "model page emits WebPage, breadcrumb, and application JSON-LD", %{conn: conn} do
    html =
      conn
      |> get("/models/openai/gpt-4o")
      |> html_response(200)

    schemas = json_ld(html)
    types = Enum.map(schemas, & &1["@type"])
    model_url = PetalBoilerplateWeb.Endpoint.url() <> "/models/openai/gpt-4o"

    assert types == ["WebPage", "BreadcrumbList", "SoftwareApplication"]

    assert Enum.all?(schemas, fn schema ->
             schema["url"] == model_url or schema["@type"] == "BreadcrumbList"
           end)
  end

  test "about and history pages emit page-specific JSON-LD", %{conn: conn} do
    about =
      conn
      |> get("/about")
      |> html_response(200)
      |> json_ld()

    history =
      build_conn()
      |> get("/history")
      |> html_response(200)
      |> json_ld()

    assert Enum.map(about, & &1["@type"]) == ["AboutPage"]
    assert Enum.map(history, & &1["@type"]) == ["CollectionPage"]
  end

  test "LLM models list emits a CollectionPage with an ItemList", %{conn: conn} do
    [schema, breadcrumb] =
      conn
      |> get("/llm-models")
      |> html_response(200)
      |> json_ld()

    assert schema["@type"] == "CollectionPage"
    assert schema["url"] == PetalBoilerplateWeb.Endpoint.url() <> "/llm-models"
    assert "LLM models list" in schema["keywords"]
    assert schema["mainEntity"]["@type"] == "ItemList"
    assert schema["mainEntity"]["numberOfItems"] > 0
    assert length(schema["mainEntity"]["itemListElement"]) == 50
    assert breadcrumb["@type"] == "BreadcrumbList"

    assert Enum.map(breadcrumb["itemListElement"], & &1["name"]) == [
             "LLM Model Database",
             "LLM Models List"
           ]
  end

  test "catalog landing pages emit CollectionPage and ItemList data", %{conn: conn} do
    [schema, breadcrumb] =
      conn
      |> get("/models/vision")
      |> html_response(200)
      |> json_ld()

    assert schema["@type"] == "CollectionPage"
    assert schema["url"] == PetalBoilerplateWeb.Endpoint.url() <> "/models/vision"
    assert schema["mainEntity"]["@type"] == "ItemList"
    assert schema["mainEntity"]["numberOfItems"] > 0
    assert length(schema["mainEntity"]["itemListElement"]) == 50
    assert breadcrumb["@type"] == "BreadcrumbList"

    assert Enum.map(breadcrumb["itemListElement"], & &1["name"]) == [
             "LLM Model Database",
             "LLM Models List",
             "Vision LLM Models"
           ]
  end

  defp json_ld(html) do
    ~r/<script type="application\/ld\+json"[^>]*>\s*(.*?)\s*<\/script>/s
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.map(fn [json] -> Jason.decode!(json) end)
  end
end
