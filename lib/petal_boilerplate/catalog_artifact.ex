defmodule PetalBoilerplate.CatalogArtifact do
  @moduledoc false

  @manifest "catalog-manifest.json"
  @asset "catalog-full.json"
  @origin "https://github.com/agentjido/llmdb/releases/download"
  @max_bytes 64_000_000

  def load do
    dir =
      Application.get_env(
        :petal_boilerplate,
        :catalog_artifact_dir,
        Application.app_dir(:petal_boilerplate, "priv/llm_db")
      )

    case File.read(Path.join(dir, @manifest)) do
      {:ok, raw} -> load_pinned(raw, dir)
      {:error, :enoent} -> load_packaged()
      {:error, reason} -> {:error, reason}
    end
  end

  def stage(dir, version, mode) when mode in [:new_pin, :existing_pin] do
    File.mkdir_p!(dir)

    with true <- Regex.match?(~r/\A\d{4}\.\d{1,2}\.\d+\z/, version),
         {:ok, raw} <- manifest_bytes(dir, version, mode),
         {:ok, manifest} <- parse_manifest(raw, version),
         {:ok, content} <- download(version, @asset, manifest["bytes"]),
         :ok <- verify(content, manifest),
         {:ok, _snapshot} <- LLMDB.Snapshot.decode(content),
         :ok <- write_atomic(Path.join(dir, @asset), content) do
      write_atomic(Path.join(dir, @manifest), raw)
    else
      false -> {:error, :invalid_release_version}
      error -> error
    end
  end

  defp load_pinned(raw, dir) do
    path = Path.join(dir, @asset)

    with {:ok, manifest} <- parse_manifest(raw, to_string(Application.spec(:llm_db, :vsn))),
         %{"bytes" => size, "snapshot_id" => id} <- manifest,
         {:ok, %{size: ^size}} <- File.stat(path),
         {:ok, content} <- File.read(path),
         :ok <- verify(content, manifest),
         {:ok, %{meta: %{source_snapshot_id: ^id}}} <-
           LLMDB.load(snapshot_source: {:file, path}, allow: :all, deny: %{}, custom: %{}) do
      :ok
    else
      {:ok, _mismatch} -> {:error, :catalog_identity_mismatch}
      error -> error
    end
  end

  defp load_packaged do
    case LLMDB.load() do
      {:ok, _snapshot} ->
        :ok

      {:error, _reason} ->
        {:ok, _snapshot} = LLMDB.load_empty()
        :ok
    end
  end

  defp parse_manifest(raw, version) do
    with {:ok,
          %{
            "version" => 1,
            "release_version" => ^version,
            "asset" => @asset,
            "snapshot_id" => id,
            "bytes" => bytes,
            "sha256" => sha
          } = manifest} <- Jason.decode(raw),
         true <- is_integer(bytes) and bytes > 0 and bytes <= @max_bytes,
         true <- hex_digest?(id) and hex_digest?(sha) do
      {:ok, manifest}
    else
      _ -> {:error, :invalid_catalog_manifest}
    end
  end

  defp hex_digest?(value) do
    is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value)
  end

  defp verify(content, %{"bytes" => size, "sha256" => digest, "snapshot_id" => id}) do
    if byte_size(content) == size and
         Base.encode16(:crypto.hash(:sha256, content), case: :lower) == digest do
      case Jason.decode(content) do
        {:ok, %{"snapshot_id" => ^id}} -> :ok
        _ -> {:error, :catalog_identity_mismatch}
      end
    else
      {:error, :catalog_digest_mismatch}
    end
  end

  defp manifest_bytes(dir, _version, :existing_pin), do: File.read(Path.join(dir, @manifest))
  defp manifest_bytes(_dir, version, :new_pin), do: download(version, @manifest, 4_096)

  defp download(version, asset, limit) do
    args = [
      "--fail",
      "--silent",
      "--show-error",
      "--location",
      "--proto",
      "=https",
      "--proto-redir",
      "=https",
      "--max-time",
      "60",
      "--max-filesize",
      Integer.to_string(limit),
      "#{@origin}/#{version}/#{asset}"
    ]

    case System.cmd("curl", args) do
      {content, 0} -> {:ok, content}
      {_message, status} -> {:error, {:catalog_download_failed, asset, status}}
    end
  end

  defp write_atomic(path, content) do
    temporary = path <> ".tmp"
    with :ok <- File.write(temporary, content), do: File.rename(temporary, path)
  end
end
