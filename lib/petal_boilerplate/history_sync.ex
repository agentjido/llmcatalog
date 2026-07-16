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

  def start_link(_opts) do
    Task.start_link(fn ->
      History.configure_runtime_bundle()
      Catalog.refresh_cache()
    end)
  end
end
