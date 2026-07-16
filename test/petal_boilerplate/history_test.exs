defmodule PetalBoilerplate.HistoryTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.History

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "petal_boilerplate_history_test_#{System.unique_integer([:positive])}"
      )

    bundled_dir = Path.join(root, "bundled")
    history_dir = Path.join([root, "missing", "nested", "runtime"])
    original_history_dir = System.get_env("LLMDB_HISTORY_DIR")
    original_bundled_dir = Application.get_env(:petal_boilerplate, :bundled_history_dir)
    original_llm_db_history_dir = Application.get_env(:llm_db, :history_dir)

    File.mkdir_p!(bundled_dir)
    File.write!(Path.join(bundled_dir, "meta.json"), Jason.encode!(%{"to_snapshot_id" => "test"}))
    System.put_env("LLMDB_HISTORY_DIR", history_dir)
    Application.put_env(:petal_boilerplate, :bundled_history_dir, bundled_dir)

    on_exit(fn ->
      restore_system_env("LLMDB_HISTORY_DIR", original_history_dir)
      restore_app_env(:petal_boilerplate, :bundled_history_dir, original_bundled_dir)
      restore_app_env(:llm_db, :history_dir, original_llm_db_history_dir)
      File.rm_rf(root)
    end)

    %{bundled_dir: bundled_dir, history_dir: history_dir}
  end

  test "seeds an unavailable runtime directory from the bundled history", %{
    bundled_dir: bundled_dir,
    history_dir: history_dir
  } do
    assert history_dir == History.configure_runtime_directory()

    assert File.read!(Path.join(history_dir, "meta.json")) ==
             File.read!(Path.join(bundled_dir, "meta.json"))
  end

  test "preserves an existing runtime history bundle", %{history_dir: history_dir} do
    File.mkdir_p!(history_dir)

    File.write!(
      Path.join(history_dir, "meta.json"),
      Jason.encode!(%{"to_snapshot_id" => "newer"})
    )

    assert history_dir == History.configure_runtime_directory()

    assert %{"to_snapshot_id" => "newer"} =
             history_dir |> Path.join("meta.json") |> File.read!() |> Jason.decode!()
  end

  defp restore_system_env(key, nil), do: System.delete_env(key)
  defp restore_system_env(key, value), do: System.put_env(key, value)

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
