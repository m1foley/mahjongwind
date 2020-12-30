defmodule MjwWeb.GameController do
  use MjwWeb, :controller

  def create(conn, _params) do
    # %{id: id, name: player_name} = current_player(conn)
    game = MjwWeb.GameStore.create()
    redirect(conn, to: Routes.game_show_path(conn, :show, game.id))
  end
end
