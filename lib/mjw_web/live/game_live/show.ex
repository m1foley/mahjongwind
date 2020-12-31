defmodule MjwWeb.GameLive.Show do
  use MjwWeb, :live_view

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> subscribe_to_game_updates
      |> fetch_game(id)
      |> assign_game_info

    {:ok, socket}
  end

  defp subscribe_to_game_updates(socket) do
    # if connected?(socket), do: MjwWeb.GameStore.subscribe(game)
    socket
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

  defp assign_game_info(socket) do
    assign_game_info(socket, socket.assigns[:game])
  end

  defp assign_game_info(socket, nil) do
    # skip if game wasn't fetched
    socket
  end

  defp assign_game_info(socket, game) do
    socket
    |> assign(:empty_seats_count, Mjw.Game.empty_seats_count(game))
    |> assign(:current_user_seat, 0)
  end
end
