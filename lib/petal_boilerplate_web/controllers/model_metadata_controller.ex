defmodule PetalBoilerplateWeb.ModelMetadataController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.APIProblem

  @fields ~w(id provider name release_date last_updated knowledge limits cost pricing
             modalities capabilities tags deprecated retired lifecycle catalog_only aliases)a

  def show(conn, %{"provider" => provider, "id" => parts}) do
    id = Enum.join(parts, "/")

    with true <- byte_size(provider) in 1..128 and byte_size(id) in 1..512,
         {:ok, provider_key} <- LLMDB.Spec.parse_provider(provider),
         ^provider <- Atom.to_string(provider_key),
         %{meta: %{source_snapshot_id: snapshot_id}, models_by_key: models}
         when is_binary(snapshot_id) <- LLMDB.snapshot(),
         %LLMDB.Model{} = model <- Map.get(models, {provider_key, id}) do
      conn
      |> put_resp_header("x-robots-tag", "noindex")
      |> json(%{schema_version: 1, snapshot_id: snapshot_id, model: Map.take(model, @fields)})
    else
      _ ->
        APIProblem.respond(
          conn,
          :not_found,
          "model_not_found",
          "No model has that provider and ID.",
          resolution: "Check the exact provider and model ID on the catalog home page."
        )
    end
  end
end
