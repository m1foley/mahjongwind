defmodule Mjw.Seat do
  defstruct covered: [], exposed: [], player_id: nil, player_name: nil

  def empty?(%__MODULE__{player_id: nil}), do: true
  def empty?(%__MODULE__{player_id: _}), do: false

  def seat_player(%__MODULE__{} = seat, player_id, player_name) do
    Map.merge(seat, %{player_id: player_id, player_name: player_name})
  end
end
