defmodule PetalBoilerplate.HistorySyncTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.HistorySync

  defmodule HistorySuccessStub do
    def configure_runtime_bundle do
      send(test_pid(), :history_synced)
      :ok
    end

    defp test_pid, do: Application.fetch_env!(:petal_boilerplate, :history_sync_test_pid)
  end

  defmodule HistoryFailureStub do
    def configure_runtime_bundle do
      send(test_pid(), :history_sync_failed)
      {:error, :offline}
    end

    defp test_pid, do: Application.fetch_env!(:petal_boilerplate, :history_sync_test_pid)
  end

  defmodule CatalogStub do
    def refresh_cache do
      send(test_pid(), :catalog_refreshed)
      :ok
    end

    defp test_pid, do: Application.fetch_env!(:petal_boilerplate, :history_sync_test_pid)
  end

  setup do
    original_pid = Application.get_env(:petal_boilerplate, :history_sync_test_pid)
    Application.put_env(:petal_boilerplate, :history_sync_test_pid, self())

    on_exit(fn -> restore_env(:history_sync_test_pid, original_pid) end)
  end

  test "refreshes the catalog after a successful history sync" do
    {:ok, pid} =
      HistorySync.start_link(history_module: HistorySuccessStub, catalog_module: CatalogStub)

    assert_receive :history_synced
    assert_receive :catalog_refreshed
    assert is_pid(pid)
  end

  test "keeps the current catalog when history sync fails" do
    {:ok, pid} =
      HistorySync.start_link(history_module: HistoryFailureStub, catalog_module: CatalogStub)

    assert_receive :history_sync_failed
    refute_receive :catalog_refreshed, 50
    assert is_pid(pid)
  end

  defp restore_env(key, nil), do: Application.delete_env(:petal_boilerplate, key)
  defp restore_env(key, value), do: Application.put_env(:petal_boilerplate, key, value)
end
