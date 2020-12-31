defmodule MjwWeb.GameController do
  use MjwWeb, :controller

  def create(conn, _params) do
    game = MjwWeb.GameStore.create()
    game_path = Routes.game_show_path(conn, :show, game.id)
    redirect(conn, to: game_path)
  end
end
