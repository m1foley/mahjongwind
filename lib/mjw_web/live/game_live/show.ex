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
      |> ensure_game_joinable

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
        # assign null object so the rest of the code can run confidently
        |> assign(:game, %Mjw.Game{})

      game ->
        socket
        |> assign(:game, game)
    end
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    empty_seats_count = Mjw.Game.empty_seats_count(game)
    current_user_sitting_at = Mjw.Game.sitting_at(game, socket.assigns.current_user_id)

    socket
    |> assign(:empty_seats_count, empty_seats_count)
    |> assign(:current_user_sitting_at, current_user_sitting_at)
  end

  defp ensure_game_joinable(socket) do
    if socket.assigns.empty_seats_count == 0 &&
         !socket.assigns.current_user_sitting_at do
      socket
      |> put_flash(:error, "Sorry, that game is full.")
      |> push_redirect(to: Routes.game_index_path(socket, :index))
    else
      socket
    end
  end
end
