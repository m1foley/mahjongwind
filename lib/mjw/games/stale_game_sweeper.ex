defmodule Mjw.Games.StaleGameSweeper do
  @moduledoc """
  Periodic cleanup of stale games
  """
  require Logger
  use GenServer

  alias Mjw.Repo
  alias Mjw.Games.GameRecord
  alias Mjw.Games.GameSerializer
  alias MjwWeb.GameStore

  import Ecto.Query

  # A stale game is when updated_at exceeds this age
  @expiration_minutes 60

  # How often to run the sweep
  @sweep_interval_ms :timer.minutes(5)

  # --- Client API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Manually trigger a sweep. Deletes all stale games.
  """
  def sweep do
    stale_games()
    |> Enum.each(fn game ->
      Logger.info("Deleting stale game. uuid=#{game.uuid}")
      GameStore.remove(game)
    end)

    :ok
  end

  @doc """
  Returns all stale games, based on updated_at age
  """
  def stale_games do
    cutoff = DateTime.utc_now() |> DateTime.add(-@expiration_minutes, :minute)

    from(g in GameRecord, where: g.updated_at < ^cutoff)
    |> Repo.all()
    |> Enum.map(&GameSerializer.from_map(&1.state))
  end

  # --- Server Callbacks ---

  @impl true
  def init([]) do
    schedule_sweep()
    {:ok, []}
  end

  @impl true
  def handle_info(:sweep, state) do
    sweep()
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @sweep_interval_ms)
  end
end
