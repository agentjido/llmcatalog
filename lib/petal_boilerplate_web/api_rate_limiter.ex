defmodule PetalBoilerplateWeb.APIRateLimiter do
  @moduledoc """
  Enforces a small, per-instance quota for the public API.

  The service has no accounts or API keys. The quota protects the shared
  public interface and gives automated clients enough information to back off.
  """

  use GenServer

  @type result ::
          {:allow, non_neg_integer(), pos_integer()}
          | {:deny, non_neg_integer(), pos_integer()}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec check(term()) :: result()
  def check(client_key) do
    GenServer.call(__MODULE__, {:check, client_key})
  end

  @impl true
  def init(_opts), do: {:ok, %{window: nil, clients: %{}}}

  @impl true
  def handle_call({:check, client_key}, _from, state) do
    {limit, window_seconds} = policy()
    now = System.system_time(:second)
    window = div(now, window_seconds)
    reset_seconds = window_seconds - rem(now, window_seconds)
    clients = if state.window == window, do: state.clients, else: %{}
    count = Map.get(clients, client_key, 0) + 1
    remaining = max(limit - count, 0)
    clients = Map.put(clients, client_key, count)

    result =
      if count <= limit, do: {:allow, remaining, reset_seconds}, else: {:deny, 0, reset_seconds}

    {:reply, result, %{window: window, clients: clients}}
  end

  @spec policy() :: {pos_integer(), pos_integer()}
  def policy do
    config = Application.get_env(:petal_boilerplate, :api_rate_limit, [])
    {Keyword.get(config, :limit, 120), Keyword.get(config, :window_seconds, 60)}
  end
end
