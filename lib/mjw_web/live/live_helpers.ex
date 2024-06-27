defmodule MjwWeb.LiveHelpers do
  use Phoenix.LiveView

  @doc """
  Take the user_id from the session and make it available to LiveViews
  """
  def assign_defaults(socket, %{"user_id" => user_id}) do
    socket |> assign(current_user_id: user_id)
  end

  # A plug ensures user_id is always in the session so this should never happen
  def assign_defaults(socket, _invalid_session) do
    socket |> redirect(to: "/")
  end
end
