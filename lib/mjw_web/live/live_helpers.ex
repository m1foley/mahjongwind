defmodule MjwWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, %{"user_id" => user_id}, socket) do
    {:cont, assign(socket, current_user_id: user_id)}
  end

  def on_mount(:default, _params, _invalid_session, socket) do
    {:halt, push_navigate(socket, to: "/")}
  end
end
