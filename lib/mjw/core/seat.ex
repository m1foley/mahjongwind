defmodule Mjw.Seat do
  defstruct concealed: [],
            exposed: [],
            hiddengongs: [],
            player_id: nil,
            player_name: nil,
            picked_wind: nil,
            picked_wind_idx: nil,
            wintile: nil,
            # Reaction to a declared win:
            # - nil = not confirmed
            # - :ok = confirmed
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
    %{seat | concealed: [], exposed: [], hiddengongs: [], wintile: nil, winreaction: nil}
  end

  @doc """
  True if the given player confirmed the declared win
  """
  def confirmed_win?(%__MODULE__{winreaction: winreaction}) do
    winreaction in [:ok, :expose_ok]
  end

  @doc """
  Confirm another player's declared win
  """
  def confirm_win(%__MODULE__{} = seat)
      when seat.winreaction in [:expose, :expose_ok] do
    %{seat | winreaction: :expose_ok}
  end

  def confirm_win(%__MODULE__{} = seat) do
    %{seat | winreaction: :ok}
  end

  @doc """
  Expose the player's hand to other players after a loss
  """
  def expose_loser_hand(%__MODULE__{} = seat)
      when seat.winreaction in [:ok, :expose_ok] do
    %{seat | winreaction: :expose_ok}
  end

  def expose_loser_hand(%__MODULE__{} = seat) do
    %{seat | winreaction: :expose}
  end

  @doc """
  Clear attributes related to declaring/confirming a win
  """
  def clear_win_attributes(%__MODULE__{} = seat) do
    %{seat | wintile: nil, winreaction: nil}
  end

  def declare_win(%__MODULE__{} = seat, wintile) do
    %{seat | wintile: wintile, winreaction: :expose}
  end

  def declared_win?(%__MODULE__{wintile: nil}), do: false
  def declared_win?(%__MODULE__{}), do: true

  def win_expose?(%__MODULE__{winreaction: winreaction}) do
    winreaction in [:expose, :expose_ok]
  end
end
