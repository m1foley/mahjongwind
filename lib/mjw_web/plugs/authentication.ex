defmodule MjwWeb.Plugs.Authentication do
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    conn
    |> fetch_session()
    |> ensure_user_id()
    |> assign_curent_user_id()
  end

  defp ensure_user_id(conn) do
    if get_session_user_id(conn) do
      conn
    else
      create_session_user_id(conn)
    end
  end

  defp get_session_user_id(conn) do
    get_session(conn, :user_id)
  end

  def create_session_user_id(conn) do
    put_session(conn, :user_id, UUID.uuid4())
  end

  def assign_curent_user_id(conn) do
    assign(conn, :current_user_id, get_session_user_id(conn))
  end
end
