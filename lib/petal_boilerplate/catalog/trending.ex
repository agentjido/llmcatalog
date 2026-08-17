defmodule PetalBoilerplate.Catalog.Trending do
  @moduledoc """
  Keeps external model ranks in memory and refreshes them at a fixed interval.

  The catalog can use an empty snapshot. Thus, an external service failure does
  not stop the application or the landing page.
  """

  use GenServer

  require Logger

  @snapshot_key {__MODULE__, :snapshot}
  @default_refresh_interval_ms :timer.hours(6)
  @retry_interval_ms :timer.minutes(15)
  @request_timeout_ms 15_000
  @openrouter_models_url "https://openrouter.ai/api/v1/models"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns the current rank snapshot without a GenServer call."
  def snapshot do
    :persistent_term.get(@snapshot_key, empty_snapshot())
  end

  @doc "Requests an immediate background refresh."
  def refresh_now do
    GenServer.cast(__MODULE__, :refresh)
  end

  @doc false
  def put_snapshot(snapshot) when is_map(snapshot) do
    normalized =
      empty_snapshot()
      |> Map.merge(snapshot)
      |> Map.update!(:popular, &normalize_ranks/1)
      |> Map.update!(:intelligence, &normalize_ranks/1)

    :persistent_term.put(@snapshot_key, normalized)
    :ok
  end

  @doc false
  def reset do
    :persistent_term.erase(@snapshot_key)
    :ok
  end

  @impl true
  def init(_opts) do
    config = Application.get_env(:petal_boilerplate, __MODULE__, [])
    enabled? = Keyword.get(config, :enabled, true)
    interval = Keyword.get(config, :refresh_interval_ms, @default_refresh_interval_ms)

    state = %{enabled?: enabled?, interval: interval, refreshing?: false}

    if enabled? do
      {:ok, state, {:continue, :refresh}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_continue(:refresh, state) do
    {:noreply, start_refresh(state)}
  end

  @impl true
  def handle_cast(:refresh, %{enabled?: true} = state) do
    {:noreply, start_refresh(state)}
  end

  def handle_cast(:refresh, state), do: {:noreply, state}

  @impl true
  def handle_info(:refresh, state) do
    {:noreply, start_refresh(state)}
  end

  def handle_info({ref, result}, %{refreshing?: ref} = state) do
    Process.demonitor(ref, [:flush])

    next_interval =
      case result do
        {:ok, snapshot} ->
          put_snapshot(snapshot)
          state.interval

        {:error, reason} ->
          Logger.warning("Trending model ranks could not refresh: #{inspect(reason)}")
          @retry_interval_ms
      end

    Process.send_after(self(), :refresh, next_interval)
    {:noreply, %{state | refreshing?: false}}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{refreshing?: ref} = state) do
    Logger.warning("Trending model rank refresh stopped: #{inspect(reason)}")
    Process.send_after(self(), :refresh, @retry_interval_ms)
    {:noreply, %{state | refreshing?: false}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp start_refresh(%{refreshing?: false} = state) do
    task = Task.async(fn -> safe_fetch_snapshot() end)
    %{state | refreshing?: task.ref}
  end

  defp start_refresh(state), do: state

  defp safe_fetch_snapshot do
    fetch_snapshot()
  rescue
    exception -> {:error, {:exception, Exception.message(exception)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp fetch_snapshot do
    with {:ok, popular} <- fetch_ranks("most-popular"),
         {:ok, intelligence} <- fetch_ranks("intelligence-high-to-low") do
      {:ok,
       %{
         popular: popular,
         intelligence: intelligence,
         refreshed_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
       }}
    end
  end

  defp fetch_ranks(sort) do
    url = @openrouter_models_url <> "?output_modalities=text&sort=" <> sort
    request = Finch.build(:get, url, [{"accept", "application/json"}])

    case Finch.request(request, PetalBoilerplate.Finch, receive_timeout: @request_timeout_ms) do
      {:ok, %{status: 200, body: body}} -> decode_ranks(body)
      {:ok, %{status: status}} -> {:error, {:http_status, status, sort}}
      {:error, reason} -> {:error, {:request_failed, sort, reason}}
    end
  end

  defp decode_ranks(body) do
    with {:ok, %{"data" => models}} when is_list(models) <- Jason.decode(body) do
      ranks =
        models
        |> Enum.map(&Map.get(&1, "id"))
        |> Enum.filter(&is_binary/1)
        |> Enum.with_index(1)
        |> Map.new()

      {:ok, ranks}
    else
      _ -> {:error, :invalid_openrouter_response}
    end
  end

  defp normalize_ranks(ranks) when is_map(ranks), do: ranks

  defp normalize_ranks(ids) when is_list(ids) do
    ids
    |> Enum.with_index(1)
    |> Map.new()
  end

  defp normalize_ranks(_value), do: %{}

  defp empty_snapshot do
    %{popular: %{}, intelligence: %{}, refreshed_at: nil}
  end
end
