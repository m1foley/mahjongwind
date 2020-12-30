defmodule MjwWeb.GameController do
  use MjwWeb, :controller

  def create(conn, _params) do
    # %{id: id, name: player_name} = current_player(conn)
    _game = MjwWeb.GameStore.create()
    # redirect(conn, to: Routes.game_path(conn, :show, game.id))
    redirect(conn, to: "/")
  end
end
