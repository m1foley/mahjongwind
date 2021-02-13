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
    assert_received({^game, :game_created})
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
    assert_received({^game, :game_removed})
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

  test "update updates a game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})
    result = MjwWeb.GameStore.update(updated_game, :event1)
    assert result == updated_game
    assert MjwWeb.GameStore.get(game.id) == updated_game
  end

  test "update with no details broadcasts the event" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})

    :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
    MjwWeb.GameStore.update(updated_game, :event1)
    assert_received({^updated_game, :event1, %{}})
  end

  test "update with detail broadcasts the event" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})

    :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
    MjwWeb.GameStore.update(updated_game, :event1, :detail1)
    assert_received({^updated_game, :event1, :detail1})
  end

  test "update does not broadcast change to lobby" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})

    :ok = MjwWeb.GameStore.subscribe_to_lobby_updates()
    MjwWeb.GameStore.update(updated_game, :event1)
    :ok = MjwWeb.GameStore.unsubscribe_from_lobby_updates()
    refute_received({_game, :event1, _detail})
  end

  test "update_with_lobby_change updates a game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})
    result = MjwWeb.GameStore.update_with_lobby_change(updated_game, :event1)
    assert result == updated_game
    assert MjwWeb.GameStore.get(game.id) == updated_game
  end

  test "update_with_lobby_change with details broadcasts change to game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})

    :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
    MjwWeb.GameStore.update_with_lobby_change(updated_game, :event1, %{foo: :bar})
    :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)
    assert_received({^updated_game, :event1, %{foo: :bar}})
  end

  test "update_with_lobby_change with no details broadcasts change to game" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})

    :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
    MjwWeb.GameStore.update_with_lobby_change(updated_game, :event1)
    :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)
    assert_received({^updated_game, :event1, %{}})
  end

  test "update_with_lobby_change broadcasts change to lobby" do
    game = MjwWeb.GameStore.create()
    updated_game = game |> Map.merge(%{turn_seatno: 1})

    :ok = MjwWeb.GameStore.subscribe_to_lobby_updates()
    MjwWeb.GameStore.update_with_lobby_change(updated_game, :event1)
    :ok = MjwWeb.GameStore.unsubscribe_from_lobby_updates()
    assert_received({^updated_game, :event1})
  end
end
