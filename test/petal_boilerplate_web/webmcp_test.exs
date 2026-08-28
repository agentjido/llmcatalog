defmodule PetalBoilerplateWeb.WebMCPTest do
  use ExUnit.Case, async: true

  test "browser bundle source registers the public catalog tools" do
    source = File.read!("assets/js/webmcp.js")
    app_source = File.read!("assets/js/app.js")

    assert source =~ "document.modelContext"
    assert source =~ "navigator.modelContext"
    assert source =~ "registerTool"
    assert source =~ ~s(name: "query_models")
    assert source =~ ~s(name: "get_model")
    assert source =~ ~s(name: "list_providers")
    assert source =~ ~s(readOnlyHint: true)
    assert source =~ ~s(fetch("/api/mcp")
    assert app_source =~ ~s(import { registerWebMCPTools } from "./webmcp")
    assert app_source =~ "registerWebMCPTools();"
  end
end
