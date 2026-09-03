defmodule PetalBoilerplateWeb.ModelReleaseTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  test "the published catalog serves Astra and Gemini 3.8 Flash pages", %{conn: conn} do
    for {provider, model_id, name} <- [
          {"openai", "gpt-6-astra", "GPT-6 Astra"},
          {"google", "gemini-3.8-flash", "Gemini 3.8 Flash"}
        ] do
      model = Catalog.get_model(provider, model_id)
      assert model.name == name
      assert model.model_id == model_id

      html = conn |> get("/models/#{provider}/#{model_id}") |> html_response(200)
      assert html =~ name
    end
  end

  test "the catalog preserves Astra access and reasoning metadata" do
    model = Catalog.get_model("openai", "gpt-6-astra")

    assert model.extra["availability"] == "limited"
    assert model.capabilities.reasoning.effort.values == ["low", "medium", "high", "xhigh", "max"]
    assert model.limits.context == 1_050_000
    assert model.limits.output == 128_000
  end
end
