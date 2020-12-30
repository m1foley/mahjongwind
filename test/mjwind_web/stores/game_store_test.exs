defmodule MjwindWeb.GameStoreTest do
  use ExUnit.Case, async: true
  doctest MjwindWeb.GameStore

  test "add adds a game" do
    game = Mjwind.Game.new()
    result = MjwindWeb.GameStore.add(game)
    assert result == :ok
  end

  test "get retrieves a game" do
    game = Mjwind.Game.new()
    MjwindWeb.GameStore.add(game)
    result = MjwindWeb.GameStore.get(game.id)
    assert result == game
  end

  test "get with a nonexistent id returns nil" do
    result = MjwindWeb.GameStore.get("nonexistent_id")
    assert result == nil
  end

  test "remove with an unpersisted id doesn't do anything" do
    unpersisted_game = Mjwind.Game.new()
    result = MjwindWeb.GameStore.remove(unpersisted_game)
    assert result == :ok
  end

  test "remove deletes the stored game" do
    game = Mjwind.Game.new()
    MjwindWeb.GameStore.add(game)
    result = MjwindWeb.GameStore.remove(game)
    assert result == :ok
    assert MjwindWeb.GameStore.get(game.id) == nil
  end
end
