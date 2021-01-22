defmodule MjwWeb.GameLiveTest do
  use MjwWeb.ConnCase

  import Phoenix.LiveViewTest

  defp fixture(:game) do
    MjwWeb.GameStore.create()
    |> Mjw.Game.seat_player("id0", "name0")
  end

  defp create_game(_) do
    %{game: fixture(:game)}
  end

  describe "Index" do
    setup [:create_game]

    test "lists all games", %{conn: conn, game: _game} do
      {:ok, _index_live, html} = live(conn, Routes.game_index_path(conn, :index))

      assert html =~ "Games"
      assert html =~ "name0"
    end
  end
end
