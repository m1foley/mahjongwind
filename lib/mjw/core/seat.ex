defmodule Mjw.Seat do
  defstruct concealed: [],
            exposed: [],
            player_id: nil,
            player_name: nil,
            picked_wind: nil,
            picked_wind_idx: nil

  def empty?(%__MODULE__{player_id: nil}), do: true
  def empty?(%__MODULE__{player_id: _id}), do: false

  def seat_player(seat, player_id, player_name) do
    seat |> Map.merge(%{player_id: player_id, player_name: player_name})
  end

  def pick_wind(seat, picked_wind, picked_wind_idx) do
    seat |> Map.merge(%{picked_wind: picked_wind, picked_wind_idx: picked_wind_idx})
  end
end
