defmodule MjwWeb.GameStoreTest do
  use ExUnit.Case, async: true
  doctest MjwWeb.GameStore

  test "create creates a new game" do
    game = MjwWeb.GameStore.create()
    assert game.id
  end

  test "create broadcasts change to lobby" do
    :ok = MjwWeb.GameStore.subscribe_to_lobby_updates()
    game = MjwWeb.GameStore.create()
    :ok = MjwWeb.GameStore.unsubscribe_from_lobby_updates()
    assert_received({:game_created, ^game})
  end

  test "persist persists a game" do
    game = Mjw.Game.new()
    result = MjwWeb.GameStore.persist(game)
    assert result == game
  end

  test "get retrieves a game" do
    game = MjwWeb.GameStore.create()
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
    assert result == unpersisted_game
  end

  test "remove deletes the stored game" do
    game = MjwWeb.GameStore.create()
    result = MjwWeb.GameStore.remove(game)
    assert result == game
    assert MjwWeb.GameStore.get(game.id) == nil
  end

  test "remove broadcasts change to lobby" do
    game = MjwWeb.GameStore.create()
    :ok = MjwWeb.GameStore.subscribe_to_lobby_updates()
    MjwWeb.GameStore.remove(game)
    :ok = MjwWeb.GameStore.unsubscribe_from_lobby_updates()
    assert_received({:game_removed, ^game})
  end

  test "clear deletes all games" do
    result = MjwWeb.GameStore.clear()
    assert result == :ok
    assert MjwWeb.GameStore.all() == []
  end

  test "all retrieves all games" do
    MjwWeb.GameStore.clear()
    games = 0..3 |> Enum.map(fn _ -> MjwWeb.GameStore.create() end)
    result = MjwWeb.GameStore.all()
    assert Enum.sort_by(result, & &1.id) == Enum.sort_by(games, & &1.id)
  end

  test "update/1 updates a game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seat_idx: 1})
    result = MjwWeb.GameStore.update(updated_game)
    assert result == updated_game
    assert MjwWeb.GameStore.get(game.id) == updated_game
  end

  test "update/1 broadcasts change to game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seat_idx: 1})

    :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
    MjwWeb.GameStore.update(updated_game)
    :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)
    assert_received({:game_updated, ^updated_game})
  end

  test "update/1 does not broadcast change to lobby" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seat_idx: 1})

    :ok = MjwWeb.GameStore.subscribe_to_lobby_updates()
    MjwWeb.GameStore.update(updated_game)
    :ok = MjwWeb.GameStore.unsubscribe_from_lobby_updates()
    refute_received({:game_updated, _game})
  end

  test "update/2 updates a game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seat_idx: 1})
    result = MjwWeb.GameStore.update(updated_game, :change_appears_in_lobby)
    assert result == updated_game
    assert MjwWeb.GameStore.get(game.id) == updated_game
  end

  test "update/2 broadcasts change to game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seat_idx: 1})

    :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
    MjwWeb.GameStore.update(updated_game, :change_appears_in_lobby)
    :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)
    assert_received({:game_updated, ^updated_game})
  end

  test "update/2 broadcasts change to lobby" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seat_idx: 1})

    :ok = MjwWeb.GameStore.subscribe_to_lobby_updates()
    MjwWeb.GameStore.update(updated_game, :change_appears_in_lobby)
    :ok = MjwWeb.GameStore.unsubscribe_from_lobby_updates()
    assert_received({:game_updated, ^updated_game})
  end
end
