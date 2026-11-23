defmodule PetalBoilerplate.CatalogArtifactTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.CatalogArtifact

  @tag :tmp_dir
  test "rejects a wrong version, truncated asset and wrong digest before replacing data", %{
    tmp_dir: dir
  } do
    previous = Application.get_env(:petal_boilerplate, :catalog_artifact_dir)
    Application.put_env(:petal_boilerplate, :catalog_artifact_dir, dir)

    on_exit(fn ->
      if previous do
        Application.put_env(:petal_boilerplate, :catalog_artifact_dir, previous)
      else
        Application.delete_env(:petal_boilerplate, :catalog_artifact_dir)
      end
    end)

    manifest = %{
      version: 1,
      release_version: "9999.1.1",
      snapshot_id: String.duplicate("a", 64),
      asset: "catalog-full.json",
      bytes: 3,
      sha256: String.duplicate("b", 64)
    }

    snapshot_id = LLMDB.snapshot().meta.source_snapshot_id
    path = Path.join(dir, "catalog-manifest.json")
    File.write!(path, Jason.encode!(manifest))
    assert {:error, :invalid_catalog_manifest} = CatalogArtifact.load()

    File.write!(
      path,
      Jason.encode!(%{manifest | release_version: to_string(Application.spec(:llm_db, :vsn))})
    )

    assert {:error, :enoent} = CatalogArtifact.load()

    asset = Path.join(dir, "catalog-full.json")
    File.write!(asset, "x")
    assert {:error, :catalog_identity_mismatch} = CatalogArtifact.load()

    File.write!(asset, "abc")
    assert {:error, :catalog_digest_mismatch} = CatalogArtifact.load()
    assert LLMDB.snapshot().meta.source_snapshot_id == snapshot_id
  end
end
