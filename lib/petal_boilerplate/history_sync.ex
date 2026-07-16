defmodule PetalBoilerplate.HistorySync do
  @moduledoc false

  alias PetalBoilerplate.{Catalog, History}

  @initial_retry_delay :timer.seconds(30)
  @max_retry_delay :timer.minutes(15)

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
    retry_delay = Keyword.get(opts, :retry_delay, @initial_retry_delay)
    max_retry_delay = Keyword.get(opts, :max_retry_delay, @max_retry_delay)
    max_attempts = Keyword.get(opts, :max_attempts, :infinity)

    Task.start_link(fn ->
      sync(history_module, catalog_module, retry_delay, max_retry_delay, max_attempts)
    end)
  end

  defp sync(history_module, catalog_module, retry_delay, max_retry_delay, attempts_left) do
    case history_module.configure_runtime_bundle() do
      :ok ->
        catalog_module.refresh_cache()

      {:error, _reason} when attempts_left == 1 ->
        :ok

      {:error, _reason} ->
        Process.sleep(retry_delay)

        sync(
          history_module,
          catalog_module,
          min(retry_delay * 2, max_retry_delay),
          max_retry_delay,
          decrement_attempts(attempts_left)
        )
    end
  end

  defp decrement_attempts(:infinity), do: :infinity
  defp decrement_attempts(attempts_left), do: attempts_left - 1
end
