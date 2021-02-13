defmodule Mjw.Seat do
  defstruct concealed: [],
            exposed: [],
            hidden_gongs: [],
            wintile: nil,
            player_id: nil,
            player_name: nil,
            picked_wind: nil,
            picked_wind_idx: nil

  def empty?(%__MODULE__{player_id: nil}), do: true
  def empty?(%__MODULE__{player_id: _id}), do: false

  def seat_player(%__MODULE__{} = seat, player_id, player_name) do
    %{seat | player_id: player_id, player_name: player_name}
  end

  def pick_wind(%__MODULE__{} = seat, picked_wind, picked_wind_idx) do
    %{seat | picked_wind: picked_wind, picked_wind_idx: picked_wind_idx}
  end

  def evacuate_player(%__MODULE__{} = seat) do
    %{seat | player_id: nil, player_name: nil}
  end
end
