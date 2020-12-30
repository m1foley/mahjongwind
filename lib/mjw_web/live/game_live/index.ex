defmodule MjwWeb.GameLive.Index do
  use MjwWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :games, MjwWeb.GameStore.all())}
  end
end
