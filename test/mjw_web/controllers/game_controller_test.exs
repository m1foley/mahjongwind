defmodule MjwWeb.GameControllerTest do
  use MjwWeb.ConnCase

  describe "create" do
    test "creates a game and redirects to it", %{conn: conn} do
      conn = post(conn, Routes.game_path(conn, :create))

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.game_show_path(conn, :show, id)
    end
  end
end
