defmodule PetalBoilerplateWeb.HistoryController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.APIProblem

  @default_model_limit 200
  @default_recent_limit 50

  plug :put_noindex_header

  def model(conn, %{"provider" => provider, "id" => id_parts} = params) do
    model_id = join_model_id(id_parts)
    model_key = "#{provider}:#{model_id}"
    limit = Map.get(params, "limit", @default_model_limit)
    history = history_module()

    with {:ok, events} <- history.timeline(provider, model_id, limit),
         {:ok, meta} <- history.meta() do
      if events == [] and is_nil(Catalog.find_model(provider, model_id)) do
        APIProblem.respond(
          conn,
          :not_found,
          "model_not_found",
          "The requested provider model is not in the current catalog.",
          resolution: "Check the provider and model ID on the catalog home page.",
          extras: %{model_key: model_key}
        )
      else
        json(conn, %{
          schema_version: schema_version(events),
          model_key: model_key,
          events: events,
          meta: meta
        })
      end
    else
      {:error, :invalid_limit} ->
        invalid_limit(conn)

      {:error, :history_unavailable} ->
        history_unavailable(conn)

      {:error, _reason} ->
        history_unavailable(conn)
    end
  end

  def recent(conn, params) do
    limit = Map.get(params, "limit", @default_recent_limit)
    history = history_module()

    with {:ok, events} <- history.recent(limit),
         {:ok, meta} <- history.meta() do
      json(conn, %{
        schema_version: schema_version(events),
        recent: true,
        events: events,
        meta: meta
      })
    else
      {:error, :invalid_limit} ->
        invalid_limit(conn)

      {:error, :history_unavailable} ->
        history_unavailable(conn)

      {:error, _reason} ->
        history_unavailable(conn)
    end
  end

  defp join_model_id(parts) when is_list(parts), do: Enum.join(parts, "/")
  defp join_model_id(part) when is_binary(part), do: part

  defp schema_version([]), do: 1

  defp schema_version([event | _]) do
    map_get(event, "schema_version", :schema_version) || 1
  end

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp invalid_limit(conn) do
    APIProblem.respond(
      conn,
      :bad_request,
      "invalid_limit",
      "The limit must be an integer from 1 through 1000.",
      resolution: "Use a limit query value from 1 through 1000."
    )
  end

  defp history_unavailable(conn) do
    APIProblem.respond(
      conn,
      :service_unavailable,
      "history_unavailable",
      "Model history data is temporarily unavailable.",
      resolution: "Try the request again later or use the current catalog data."
    )
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end

  defp put_noindex_header(conn, _opts) do
    put_resp_header(conn, "x-robots-tag", "noindex")
  end
end
