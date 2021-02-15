defmodule Mjw.Seat do
  defstruct concealed: [],
            exposed: [],
            hidden_gongs: [],
            player_id: nil,
            player_name: nil,
            picked_wind: nil,
            picked_wind_idx: nil,
            wintile: nil,
            # Reaction to a declared win:
            # - :ok = confirmed
            # - nil = not confirmed
            # - :expose = exposed hand, not confirmed
            # - :expose_ok = exposed hand, confirmed
            winreaction: nil

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

  @doc """
  Clear tile attributes between games
  """
  def clear_tiles(%__MODULE__{} = seat) do
    %{seat | concealed: [], exposed: [], hidden_gongs: [], wintile: nil, winreaction: nil}
  end
end
