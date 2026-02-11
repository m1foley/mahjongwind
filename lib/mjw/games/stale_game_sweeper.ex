defmodule Mjw.Games.StaleGameSweeper do
  @moduledoc """
  Periodic cleanup of stale games
  """

  use GenServer

  alias Mjw.Repo
  alias Mjw.Games.GameRecord
  alias Mjw.Games.GameSerializer
  alias MjwWeb.GameStore

  import Ecto.Query

  # Default expiration time (in minutes)
  @default_expiration_minutes 60

  # How often to run the sweep (in milliseconds)
  @sweep_interval_ms 120_000

  # --- Client API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually trigger a sweep. Deletes all games with updated_at older than
  `expiration_minutes` minutes ago.
  """
  def sweep(expiration_minutes \\ @default_expiration_minutes) do
    stale_games(expiration_minutes)
    |> Enum.each(&GameStore.remove/1)

    :ok
  end

  @doc """
  Returns all stale games (updated_at older than `expiration_minutes` minutes ago).
  """
  def stale_games(expiration_minutes \\ @default_expiration_minutes) do
    cutoff = DateTime.utc_now() |> DateTime.add(-expiration_minutes * 60, :second)

    from(g in GameRecord, where: g.updated_at < ^cutoff)
    |> Repo.all()
    |> Enum.map(&GameSerializer.from_map(&1.state))
  end

  # --- Server Callbacks ---

  @impl true
  def init(opts) do
    expiration_minutes = Keyword.get(opts, :expiration_minutes, @default_expiration_minutes)
    sweep_interval_ms = Keyword.get(opts, :sweep_interval_ms, @sweep_interval_ms)

    # Schedule the first sweep
    schedule_sweep(sweep_interval_ms)

    {:ok, %{expiration_minutes: expiration_minutes, sweep_interval_ms: sweep_interval_ms}}
  end

  @impl true
  def handle_info(:sweep, state) do
    sweep(state.expiration_minutes)
    schedule_sweep(state.sweep_interval_ms)
    {:noreply, state}
  end

  defp schedule_sweep(interval_ms) do
    Process.send_after(self(), :sweep, interval_ms)
  end
end
