defmodule Mjw.Games.GameExpirationTest do
  @moduledoc """
  Tests for game expiration when the last human player leaves.
  """
  use Mjw.DataCase, async: true

  alias Mjw.Games.Game
  alias MjwWeb.GameStore

  describe "immediate deletion when last human leaves via evacuate_seat" do
    test "game persists when human leaves but other humans remain" do
      game =
        GameStore.create()
        |> Game.seat_player("id0", "name0")
        |> Game.seat_player("id1", "name1")
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> GameStore.persist()

      # Human at seat 0 leaves
      game = Game.evacuate_seat(game, 0)

      # Game should still have a human player
      assert Game.has_human_players?(game)

      # Simulate what the LiveView would do - persist and check
      GameStore.persist(game)

      # Game should still exist
      assert GameStore.get_by_uuid(game.uuid) != nil
    end

    test "game should be deleted when last human leaves (only bots remain)" do
      game =
        GameStore.create()
        |> Game.seat_player("id0", "name0")
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> GameStore.persist()

      # Human at seat 0 leaves
      game = Game.evacuate_seat(game, 0)

      # Game should have no human players
      refute Game.has_human_players?(game)

      # When the LiveView detects no humans, it should delete the game
      # This simulates that behavior
      if not Game.has_human_players?(game) do
        GameStore.remove(game)
      end

      # Game should be deleted
      assert GameStore.get_by_uuid(game.uuid) == nil
    end

    test "game should be deleted when last human leaves (all seats empty)" do
      game =
        GameStore.create()
        |> Game.seat_player("id0", "name0")
        |> GameStore.persist()

      # Human at seat 0 leaves
      game = Game.evacuate_seat(game, 0)

      # Game should have no human players
      refute Game.has_human_players?(game)

      # When the LiveView detects no humans, it should delete the game
      if not Game.has_human_players?(game) do
        GameStore.remove(game)
      end

      # Game should be deleted
      assert GameStore.get_by_uuid(game.uuid) == nil
    end
  end

  describe "immediate deletion when last human leaves via boot" do
    test "game persists when human is booted but other humans remain" do
      game =
        GameStore.create()
        |> Game.seat_player("id0", "name0")
        |> Game.seat_player("id1", "name1")
        |> Game.seat_player("id2", "name2")
        |> Game.seat_player("id3", "name3")
        |> GameStore.persist()

      # Human at seat 1 is booted
      game = Game.boot(game, 1)

      # Game should still have human players
      assert Game.has_human_players?(game)

      GameStore.persist(game)

      # Game should still exist
      assert GameStore.get_by_uuid(game.uuid) != nil
    end

    test "game should be deleted when last human is booted (only bots remain)" do
      game =
        GameStore.create()
        |> Game.seat_player("id0", "name0")
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> GameStore.persist()

      # Human at seat 0 is booted
      game = Game.boot(game, 0)

      # Game should have no human players
      refute Game.has_human_players?(game)

      # When the LiveView detects no humans, it should delete the game
      if not Game.has_human_players?(game) do
        GameStore.remove(game)
      end

      # Game should be deleted
      assert GameStore.get_by_uuid(game.uuid) == nil
    end
  end

  describe "lobby notification on game removal" do
    test "lobby receives broadcast when game is removed after last human leaves" do
      game =
        GameStore.create()
        |> Game.seat_player("id0", "name0")
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> Game.seat_bot()
        |> GameStore.persist()

      :ok = GameStore.subscribe_to_lobby_updates()

      # Human leaves
      game = Game.evacuate_seat(game, 0)

      # Delete game since no humans remain
      GameStore.remove(game)

      :ok = GameStore.unsubscribe_from_lobby_updates()

      assert_received({^game, :game_removed})
    end
  end
end
