defmodule Mjw.Games.StaleGameSweeperTest do
  use Mjw.DataCase, async: false

  alias Mjw.Games.StaleGameSweeper
  alias Mjw.Games.GameRecord
  alias MjwWeb.GameStore

  # Helper to set a game's updated_at timestamp directly in the database
  defp set_updated_at(game, minutes_ago) do
    updated_at = DateTime.utc_now() |> DateTime.add(-minutes_ago, :minute)

    from(g in GameRecord, where: g.uuid == ^game.uuid)
    |> Repo.update_all(set: [updated_at: updated_at])

    game
  end

  describe "sweep/0" do
    test "deletes games with an updated_at more than 60 minutes ago" do
      stale = GameStore.create() |> set_updated_at(61)
      fresh = GameStore.create() |> set_updated_at(55)

      StaleGameSweeper.sweep()

      assert GameStore.get_by_uuid(stale.uuid) == nil
      assert GameStore.get_by_uuid(fresh.uuid) != nil
    end

    test "broadcasts removal to lobby for each stale game" do
      game = GameStore.create() |> set_updated_at(90)

      :ok = GameStore.subscribe_to_lobby_updates()
      StaleGameSweeper.sweep()
      :ok = GameStore.unsubscribe_from_lobby_updates()

      assert_received({^game, :game_removed})
    end

    test "does not crash when no games exist" do
      GameStore.clear()
      StaleGameSweeper.sweep()
    end
  end
end
