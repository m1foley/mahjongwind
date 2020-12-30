defmodule MjwWeb.GameStoreTest do
  use ExUnit.Case, async: true
  doctest MjwWeb.GameStore

  test "add adds a game" do
    game = Mjw.Game.new()
    result = MjwWeb.GameStore.add(game)
    assert result == :ok
  end

  test "get retrieves a game" do
    game = Mjw.Game.new()
    MjwWeb.GameStore.add(game)
    result = MjwWeb.GameStore.get(game.id)
    assert result == game
  end

  test "get with a nonexistent id returns nil" do
    result = MjwWeb.GameStore.get("nonexistent_id")
    assert result == nil
  end

  test "remove with an unpersisted id doesn't do anything" do
    unpersisted_game = Mjw.Game.new()
    result = MjwWeb.GameStore.remove(unpersisted_game)
    assert result == :ok
  end

  test "remove deletes the stored game" do
    game = Mjw.Game.new()
    MjwWeb.GameStore.add(game)
    result = MjwWeb.GameStore.remove(game)
    assert result == :ok
    assert MjwWeb.GameStore.get(game.id) == nil
  end

  test "clear deletes all games" do
    result = MjwWeb.GameStore.clear()
    assert result == :ok
    assert MjwWeb.GameStore.all() == []
  end

  test "all retrieves all games" do
    MjwWeb.GameStore.clear()
    games = 0..3 |> Enum.map(fn _ -> Mjw.Game.new() end)
    Enum.each(games, fn game -> MjwWeb.GameStore.add(game) end)
    result = MjwWeb.GameStore.all()
    assert Enum.sort_by(result, & &1.id) == Enum.sort_by(games, & &1.id)
  end
end
