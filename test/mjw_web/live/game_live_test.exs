defmodule MjwWeb.GameLiveTest do
  # async: false avoids race condition
  use MjwWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  # Global setup that runs before all tests
  setup do
    MjwWeb.GameStore.clear()
  end

  defp create_game(_context) do
    game =
      MjwWeb.GameStore.create()
      |> Mjw.Game.seat_player("id0", "name0")
      |> MjwWeb.GameStore.update(:event1)

    %{game: game}
  end

  describe "index with no existing games" do
    test "shows no games", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Mahjong Wind"
      assert html =~ "Start a game"
      refute html =~ "name0"
    end
  end

  describe "index with existing games" do
    setup [:create_game]

    test "lists all games", %{conn: conn, game: _game} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Mahjong Wind"
      assert html =~ "Start a game"
      assert html =~ "name0"
    end
  end
end
