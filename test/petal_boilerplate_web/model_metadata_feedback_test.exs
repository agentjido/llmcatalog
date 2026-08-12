defmodule PetalBoilerplateWeb.ModelMetadataFeedbackTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  alias PetalBoilerplateWeb.ModelMetadataFeedback
  alias PetalBoilerplateWeb.PublicRoutes

  test "global issue URL selects the model metadata form" do
    params = ModelMetadataFeedback.issue_url() |> query_params()

    assert params["template"] == "model_metadata.yml"
    assert params["title"] == "Model metadata correction"
  end

  test "model issue URL fills supported metadata fields" do
    model = %{provider: :anthropic, model_id: "claude/sonnet-5"}
    params = model |> ModelMetadataFeedback.issue_url() |> query_params()

    assert params["template"] == "model_metadata.yml"
    assert params["title"] == "Model metadata: Anthropic / claude/sonnet-5"
    assert params["provider"] == "Anthropic"
    assert params["model-id"] == "claude/sonnet-5"
    assert params["additional"] =~ PublicRoutes.absolute("/models/anthropic/claude/sonnet-5")
    assert params["additional"] =~ "Catalog provider: Anthropic"
  end

  test "model issue URL keeps an unlisted provider in the report context" do
    params =
      %{provider: :openrouter, model_id: "community/model"}
      |> ModelMetadataFeedback.issue_url()
      |> query_params()

    assert params["provider"] == "Other"
    assert params["title"] == "Model metadata: Openrouter / community/model"
    assert params["additional"] =~ "Catalog provider: Openrouter"
  end

  defp query_params(url) do
    url
    |> URI.parse()
    |> Map.fetch!(:query)
    |> URI.decode_query()
  end
end
