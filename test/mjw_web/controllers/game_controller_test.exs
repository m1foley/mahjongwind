defmodule MjwWeb.GameControllerTest do
  use MjwWeb.ConnCase

  describe "create" do
    test "creates a game and redirects to it", %{conn: conn} do
      conn = post(conn, ~p"/games")

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/games/#{id}"
    end
  end
end
