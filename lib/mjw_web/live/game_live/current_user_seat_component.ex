defmodule MjwWeb.GameLive.CurrentUserSeatComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:concealed_loser_hand, concealed_loser_hand?(assigns))

    {:ok, socket}
  end

  defp concealed_loser_hand?(assigns) do
    assigns.win_declared_seatno &&
      assigns.win_declared_seatno != assigns.current_user_seatno &&
      !assigns.seat.win_expose
  end
end
