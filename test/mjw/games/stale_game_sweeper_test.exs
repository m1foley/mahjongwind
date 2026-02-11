defmodule Mjw.Games.StaleGameSweeperTest do
  use Mjw.DataCase, async: false

  alias Mjw.Games.StaleGameSweeper
  alias Mjw.Games.GameRecord
  alias MjwWeb.GameStore

  # Helper to set a game's updated_at timestamp directly in the database
  defp set_updated_at(game, minutes_ago) do
    updated_at = DateTime.utc_now() |> DateTime.add(-minutes_ago * 60, :second)

    from(g in GameRecord, where: g.uuid == ^game.uuid)
    |> Repo.update_all(set: [updated_at: updated_at])

    game
  end

  describe "sweep/1" do
    test "preserves game updated 30 minutes ago" do
      game = GameStore.create()
      set_updated_at(game, 30)

      StaleGameSweeper.sweep(60)

      assert GameStore.get_by_uuid(game.uuid) != nil
    end

    test "deletes game updated 61 minutes ago" do
      game = GameStore.create()
      set_updated_at(game, 61)

      StaleGameSweeper.sweep(60)

      assert GameStore.get_by_uuid(game.uuid) == nil
    end

    test "deletes multiple stale games" do
      game1 = GameStore.create()
      game2 = GameStore.create()
      game3 = GameStore.create()

      set_updated_at(game1, 90)
      set_updated_at(game2, 120)
      set_updated_at(game3, 180)

      StaleGameSweeper.sweep(60)

      assert GameStore.get_by_uuid(game1.uuid) == nil
      assert GameStore.get_by_uuid(game2.uuid) == nil
      assert GameStore.get_by_uuid(game3.uuid) == nil
    end

    test "deletes only stale games when mixed with fresh games" do
      fresh_game = GameStore.create()
      stale_game1 = GameStore.create()
      stale_game2 = GameStore.create()

      set_updated_at(fresh_game, 30)
      set_updated_at(stale_game1, 90)
      set_updated_at(stale_game2, 120)

      StaleGameSweeper.sweep(60)

      assert GameStore.get_by_uuid(fresh_game.uuid) != nil
      assert GameStore.get_by_uuid(stale_game1.uuid) == nil
      assert GameStore.get_by_uuid(stale_game2.uuid) == nil
    end

    test "broadcasts removal to lobby for each stale game" do
      game = GameStore.create()
      set_updated_at(game, 90)

      :ok = GameStore.subscribe_to_lobby_updates()
      StaleGameSweeper.sweep(60)
      :ok = GameStore.unsubscribe_from_lobby_updates()

      assert_received({^game, :game_removed})
    end

    test "does not crash when no games exist" do
      GameStore.clear()

      # Should not raise
      StaleGameSweeper.sweep(60)
    end
  end
end
