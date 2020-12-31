defmodule Mjw.Seat do
  defstruct covered: [], exposed: [], player_id: nil, player_name: nil

  def empty?(%__MODULE__{player_id: nil}), do: true
  def empty?(%__MODULE__{player_id: _}), do: false
end
