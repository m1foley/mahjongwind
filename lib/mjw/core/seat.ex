defmodule Mjw.Seat do
  defstruct covered: [], exposed: [], player_id: nil, player_name: nil, picked_wind: nil

  def empty?(%__MODULE__{player_id: nil}), do: true
  def empty?(%__MODULE__{player_id: _id}), do: false

  def seat_player(seat, player_id, player_name) do
    seat |> Map.merge(%{player_id: player_id, player_name: player_name})
  end
end
