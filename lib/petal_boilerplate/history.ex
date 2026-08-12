defmodule PetalBoilerplate.History do
  @moduledoc """
  Wrapper around `LLMDB.History` with app-level defaults and limit validation.
  """

  require Logger

  @default_timeline_limit 200
  @default_recent_limit 50
  @max_limit 500
  @history_archive_name "petal_boilerplate-llm_db-history.tar.gz"
  @history_staging_suffix "-staging"

  alias LLMDB.{History.Bundle, Snapshot.ReleaseStore}

  @doc """
  Configures a writable history directory and syncs the published bundle when needed.
  """
  def configure_runtime_bundle do
    history_dir = configure_runtime_directory()

    case ensure_local_bundle(history_dir) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("llm_db history bundle unavailable: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Configures the writable history directory without performing network access.
  """
  def configure_runtime_directory do
    history_dir = history_dir()
    Application.put_env(:llm_db, :history_dir, history_dir)

    case seed_bundled_history(history_dir) do
      :ok ->
        :ok

      error ->
        Logger.warning("failed to seed bundled llm_db history: #{inspect(error)}")
    end

    history_dir
  end

  @doc """
  Returns the configured local history directory.
  """
  def history_dir do
    System.get_env("LLMDB_HISTORY_DIR") ||
      Path.join([System.tmp_dir!(), "petal_boilerplate", "llm_db", "history"])
  end

  @doc """
  Returns whether runtime history artifacts are available.
  """
  def available? do
    LLMDB.History.available?()
  end

  @doc """
  Returns compact history metadata for API/UI consumers.
  """
  def meta do
    with {:ok, meta} <- LLMDB.History.meta() do
      {:ok, compact_meta(meta)}
    end
  end

  @doc """
  Returns model timeline events with a validated limit.
  """
  def timeline(provider, model_id, limit \\ @default_timeline_limit) when is_binary(model_id) do
    with {:ok, normalized_limit} <- normalize_limit(limit),
         {:ok, events} <- LLMDB.History.timeline(provider, model_id) do
      {:ok, Enum.take(events, -normalized_limit)}
    end
  end

  @doc """
  Returns recent events with a validated limit.
  """
  def recent(limit \\ @default_recent_limit) do
    with {:ok, normalized_limit} <- normalize_limit(limit) do
      LLMDB.History.recent(normalized_limit)
    end
  end

  defp compact_meta(meta) do
    from_commit = map_get(meta, "from_commit", :from_commit)
    to_commit = map_get(meta, "to_commit", :to_commit)
    from_snapshot_id = map_get(meta, "from_snapshot_id", :from_snapshot_id)
    to_snapshot_id = map_get(meta, "to_snapshot_id", :to_snapshot_id)

    {range_kind, from_ref, to_ref} =
      cond do
        is_binary(from_snapshot_id) and is_binary(to_snapshot_id) ->
          {"snapshots", from_snapshot_id, to_snapshot_id}

        is_binary(from_commit) and is_binary(to_commit) ->
          {"commits", from_commit, to_commit}

        true ->
          {nil, nil, nil}
      end

    %{
      "from_commit" => map_get(meta, "from_commit", :from_commit),
      "to_commit" => map_get(meta, "to_commit", :to_commit),
      "from_snapshot_id" => from_snapshot_id,
      "to_snapshot_id" => to_snapshot_id,
      "from_ref" => from_ref,
      "to_ref" => to_ref,
      "range_kind" => range_kind,
      "generated_at" => map_get(meta, "generated_at", :generated_at),
      "snapshots_written" => map_get(meta, "snapshots_written", :snapshots_written),
      "unique_snapshots_written" =>
        map_get(meta, "unique_snapshots_written", :unique_snapshots_written),
      "events_written" => map_get(meta, "events_written", :events_written)
    }
  end

  defp normalize_limit(limit) when is_integer(limit) and limit > 0 do
    {:ok, min(limit, @max_limit)}
  end

  defp normalize_limit(limit) when is_binary(limit) do
    limit
    |> String.trim()
    |> parse_limit()
  end

  defp normalize_limit(_), do: {:error, :invalid_limit}

  defp parse_limit(""), do: {:error, :invalid_limit}

  defp parse_limit(limit) do
    case Integer.parse(limit) do
      {parsed, ""} -> normalize_limit(parsed)
      _ -> {:error, :invalid_limit}
    end
  end

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp ensure_local_bundle(history_dir) do
    case latest_available_history_release() do
      {:ok, snapshot_id, archive_url} ->
        if history_current?(history_dir, snapshot_id) do
          :ok
        else
          sync_history_bundle(history_dir, archive_url)
        end

      {:error, _reason} = error ->
        if history_available_locally?(history_dir), do: :ok, else: error
    end
  end

  defp latest_available_history_release do
    with {:ok, releases} <- fetch_releases(),
         release when is_map(release) <- Enum.find(releases, &history_release?/1),
         {:ok, meta_url} <- release_asset_url(release, "history-meta.json"),
         {:ok, archive_url} <- release_asset_url(release, "history.tar.gz"),
         {:ok, meta} <- fetch_json(meta_url),
         snapshot_id when is_binary(snapshot_id) <- meta["to_snapshot_id"] do
      {:ok, snapshot_id, archive_url}
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
      _ -> {:error, :not_found}
    end
  end

  defp history_current?(history_dir, snapshot_id) do
    case Bundle.read_meta(history_dir) do
      {:ok, %{"to_snapshot_id" => ^snapshot_id}} -> true
      _ -> false
    end
  end

  defp history_available_locally?(history_dir) do
    match?({:ok, _meta}, Bundle.read_meta(history_dir))
  end

  defp seed_bundled_history(history_dir) do
    bundled_dir = bundled_history_dir()

    cond do
      bundled_dir == history_dir ->
        :ok

      history_available_locally?(history_dir) ->
        :ok

      is_binary(bundled_dir) and history_available_locally?(bundled_dir) ->
        copy_bundled_history(bundled_dir, history_dir)

      true ->
        :ok
    end
  end

  defp bundled_history_dir do
    Application.get_env(:petal_boilerplate, :bundled_history_dir) ||
      case :code.priv_dir(:petal_boilerplate) do
        path when is_list(path) -> Path.join([List.to_string(path), "llm_db", "history"])
        _error -> nil
      end
  end

  defp copy_bundled_history(bundled_dir, history_dir) do
    staging_dir = history_dir <> @history_staging_suffix
    File.rm_rf(staging_dir)

    try do
      with :ok <- File.mkdir_p(Path.dirname(history_dir)),
           {:ok, _files} <- File.cp_r(bundled_dir, staging_dir),
           {:ok, _meta} <- Bundle.read_meta(staging_dir),
           {:ok, _files} <- File.rm_rf(history_dir),
           :ok <- File.rename(staging_dir, history_dir) do
        :ok
      end
    after
      File.rm_rf(staging_dir)
    end
  end

  defp sync_history_bundle(history_dir, archive_url) do
    archive_path = Path.join(System.tmp_dir!(), @history_archive_name)
    staging_dir = history_dir <> @history_staging_suffix

    try do
      with :ok <- download_history_archive(archive_url, archive_path),
           :ok <- replace_history_bundle(archive_path, history_dir, staging_dir) do
        :ok
      else
        error -> error
      end
    after
      File.rm(archive_path)
      File.rm_rf(staging_dir)
    end
  end

  defp replace_history_bundle(archive_path, history_dir, staging_dir) do
    File.rm_rf(staging_dir)

    with :ok <- Bundle.install_archive(archive_path, staging_dir),
         {:ok, _meta} <- Bundle.read_meta(staging_dir) do
      File.rm_rf(history_dir)
      File.rename(staging_dir, history_dir)
    end
  end

  defp download_history_archive(archive_url, archive_path) when is_binary(archive_url) do
    ensure_req_started()

    case Req.get(archive_url) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        archive_path
        |> Path.dirname()
        |> File.mkdir_p!()

        File.write!(archive_path, body)
        :ok

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_status, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp download_history_archive(_archive_url, _archive_path) do
    {:error, :not_found}
  end

  defp fetch_releases do
    repo = ReleaseStore.config().repo
    url = "https://api.github.com/repos/#{repo}/releases?per_page=100"

    fetch_json(url, headers: github_request_headers())
  end

  defp github_request_headers do
    headers = [
      {"accept", "application/vnd.github+json"},
      {"user-agent", "llmcatalog.dev"}
    ]

    case System.get_env("GH_TOKEN") || System.get_env("GITHUB_TOKEN") do
      nil -> headers
      token -> [{"authorization", "Bearer #{token}"} | headers]
    end
  end

  defp history_release?(%{"draft" => true}), do: false
  defp history_release?(%{"prerelease" => true}), do: false

  defp history_release?(release) do
    with {:ok, _meta_url} <- release_asset_url(release, "history-meta.json"),
         {:ok, _archive_url} <- release_asset_url(release, "history.tar.gz") do
      true
    else
      _ -> false
    end
  end

  defp release_asset_url(%{"assets" => assets}, filename) when is_list(assets) do
    assets
    |> Enum.find_value(fn
      %{"name" => ^filename, "browser_download_url" => url} when is_binary(url) -> url
      %{"name" => ^filename, "url" => url} when is_binary(url) -> url
      _asset -> nil
    end)
    |> case do
      url when is_binary(url) -> {:ok, url}
      nil -> {:error, :not_found}
    end
  end

  defp release_asset_url(_release, _filename), do: {:error, :not_found}

  defp fetch_json(url, opts \\ []) when is_binary(url) do
    with {:ok, body} <- http_get(url, opts) do
      decode_json_body(body)
    end
  end

  defp http_get(url, opts) when is_binary(url) do
    ensure_req_started()

    case Req.get(url, opts) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, %{status: status, body: body}} -> {:error, {:http_status, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_json_body(body) when is_binary(body), do: Jason.decode(body)
  defp decode_json_body(body) when is_map(body) or is_list(body), do: {:ok, body}
  defp decode_json_body(_body), do: {:error, :invalid_json_body}

  defp ensure_req_started do
    case Application.ensure_all_started(:req) do
      {:ok, _apps} -> :ok
      {:error, {:already_started, _app}} -> :ok
      {:error, reason} -> raise "failed to start req application: #{inspect(reason)}"
    end
  end
end
