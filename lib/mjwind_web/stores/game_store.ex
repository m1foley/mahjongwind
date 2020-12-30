defmodule MjwindWeb.GameStore do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
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
end
