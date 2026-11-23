defmodule PetalBoilerplateWeb.ModelMetadataControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "reads a slash-containing offer and returns its exact identity and snapshot", %{conn: conn} do
    conn = get(conn, "/api/v1/models/openrouter/openai/gpt-3.5-turbo-0613")

    assert %{
             "schema_version" => 1,
             "snapshot_id" => snapshot_id,
             "model" => %{"id" => "openai/gpt-3.5-turbo-0613", "provider" => "openrouter"} = model
           } = json_response(conn, 200)

    assert snapshot_id == LLMDB.snapshot().meta.source_snapshot_id
    refute Map.has_key?(model, "execution")
    refute Map.has_key?(model, "base_url")
  end

  test "returns a clear miss", %{conn: conn} do
    assert json_response(get(conn, "/api/v1/models/openai/no-such-model"), 404)
  end
end
