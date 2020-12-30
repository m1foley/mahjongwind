defmodule MjwWeb.GameStore do
  use Agent

  def initial, do: %{}

  def start_link(_opts) do
    Agent.start_link(&initial/0, name: __MODULE__)
  end

  def add(game) do
    Agent.update(__MODULE__, &Map.put(&1, game.id, game))
  end

  def remove(game) do
    Agent.update(__MODULE__, &Map.delete(&1, game.id))
  end

  def get(game_id) do
    Agent.get(__MODULE__, &Map.get(&1, game_id))
  end

  def all() do
    Agent.get(__MODULE__, &Map.values(&1))
  end

  def clear() do
    Agent.update(__MODULE__, fn _ -> initial() end)
  end
end
