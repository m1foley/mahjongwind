defmodule MjwWeb.GameLiveTest do
  use MjwWeb.ConnCase

  import Phoenix.LiveViewTest

  defp fixture(:game) do
    MjwWeb.GameStore.create()
  end

  defp create_game(_) do
    %{game: fixture(:game)}
  end

  describe "Index" do
    setup [:create_game]

    test "lists all games", %{conn: conn, game: game} do
      {:ok, _index_live, html} = live(conn, Routes.game_index_path(conn, :index))

      assert html =~ "Games"
      assert html =~ game.id
    end
  end
end
