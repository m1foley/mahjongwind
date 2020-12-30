defmodule MjwWeb.GameStore do
  use Agent

  def initial, do: %{}

  def start_link(_opts) do
    Agent.start_link(&initial/0, name: __MODULE__)
  end

  @doc """
  Create a new Game and persist it
  """
  def create do
    Mjw.Game.new()
    |> persist
  end

  def persist(game) do
    Agent.update(__MODULE__, &Map.put(&1, game.id, game))
    broadcast(game, :game_created)
  end

  def remove(game) do
    Agent.update(__MODULE__, &Map.delete(&1, game.id))
    broadcast(game, :game_removed)
  end

  def get(game_id) do
    Agent.get(__MODULE__, &Map.get(&1, game_id))
  end

  def all do
    Agent.get(__MODULE__, &Map.values(&1))
  end

  @doc """
  Remove all stored games. Only used in tests.
  """
  def clear do
    Agent.update(__MODULE__, fn _ -> initial() end)
  end

  @doc """
  Subscribe to changes in the list of lobby games
  """
  def subscribe do
    Phoenix.PubSub.subscribe(Mjw.PubSub, "games")
  end

  # Broadcast changes to the list of lobby games
  defp broadcast(game, event) do
    Phoenix.PubSub.broadcast(Mjw.PubSub, "games", {event, game})
    game
  end
end
