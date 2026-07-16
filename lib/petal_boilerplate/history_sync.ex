defmodule PetalBoilerplate.HistorySync do
  @moduledoc false

  alias PetalBoilerplate.{Catalog, History}

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  def start_link(opts) when is_list(opts) do
    history_module = Keyword.get(opts, :history_module, History)
    catalog_module = Keyword.get(opts, :catalog_module, Catalog)

    Task.start_link(fn ->
      case history_module.configure_runtime_bundle() do
        :ok -> catalog_module.refresh_cache()
        {:error, _reason} -> :ok
      end
    end)
  end
end
