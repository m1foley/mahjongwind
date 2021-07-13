defmodule MjwWeb.GameLive.LobbyGameComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_game_info()

    {:ok, socket}
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game

    seated_player_names =
      game
      |> Mjw.Game.seated_player_names()
      |> Enum.join(", ")

    assign(socket, :seated_player_names, seated_player_names)
  end
end
