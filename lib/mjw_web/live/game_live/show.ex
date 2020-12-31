defmodule MjwWeb.GameLive.Show do
  use MjwWeb, :live_view

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> subscribe_to_game_updates
      |> fetch_game(id)

    {:ok, socket}
  end

  defp subscribe_to_game_updates(session) do
    # if connected?(socket), do: MjwWeb.GameStore.subscribe(game)
    session
  end

  defp fetch_game(socket, id) do
    case MjwWeb.GameStore.get(id) do
      nil ->
        socket
        |> put_flash(:error, "That game ID does not exist.")
        |> push_redirect(to: Routes.game_index_path(socket, :index))

      game ->
        socket
        |> assign(:game, game)
    end
  end
end
