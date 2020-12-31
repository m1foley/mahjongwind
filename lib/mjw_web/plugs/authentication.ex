defmodule MjwWeb.Plugs.Authentication do
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    conn |> fetch_session |> ensure_user_id |> assign_curent_user_id
  end

  defp ensure_user_id(conn) do
    if session_user_id(conn) do
      conn
    else
      create_session_user_id(conn)
    end
  end

  defp session_user_id(conn) do
    conn |> get_session(:user_id)
  end

  def create_session_user_id(conn) do
    conn |> put_session(:user_id, UUID.uuid4())
  end

  def assign_curent_user_id(conn) do
    conn |> assign(:current_user_id, session_user_id(conn))
  end
end
