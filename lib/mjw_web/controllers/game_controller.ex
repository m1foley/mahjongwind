defmodule MjwWeb.GameController do
  use MjwWeb, :controller

  def create(conn, _params) do
    game = MjwWeb.GameStore.create()
    game_path = ~p"/games/#{game.id}"
    redirect(conn, to: game_path)
  end
end
