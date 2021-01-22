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
    |> persist()
    |> broadcast_lobby_update(:game_created)
  end

  @doc """
  Persist an update to an existing game
  """
  def update(game) do
    game
    |> persist()
    |> broadcast_game_update(:game_updated)
  end

  @doc """
  Persist a seating update to an existing game
  """
  def update_seating(game) do
    game
    |> update
    |> broadcast_seating_update(:seating_updated)
  end

  def persist(game) do
    Agent.update(__MODULE__, &Map.put(&1, game.id, game))
    game
  end

  def remove(game) do
    Agent.update(__MODULE__, &Map.delete(&1, game.id))
    broadcast_lobby_update(game, :game_removed)
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

  def subscribe_to_lobby_updates do
    Phoenix.PubSub.subscribe(Mjw.PubSub, "games")
  end

  def subscribe_to_game_updates(game) do
    Phoenix.PubSub.subscribe(Mjw.PubSub, "game:#{game.id}")
  end

  def subscribe_to_seating_updates(game) do
    Phoenix.PubSub.subscribe(Mjw.PubSub, "seats:#{game.id}")
  end

  defp broadcast_lobby_update(game, event) do
    Phoenix.PubSub.broadcast(Mjw.PubSub, "games", {event, game})
    game
  end

  defp broadcast_game_update(game, event) do
    Phoenix.PubSub.broadcast(Mjw.PubSub, "game:#{game.id}", {event, game})
    game
  end

  defp broadcast_seating_update(game, event) do
    Phoenix.PubSub.broadcast(Mjw.PubSub, "seats:#{game.id}", {event, game})
    game
  end
end
