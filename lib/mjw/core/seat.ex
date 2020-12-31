defmodule Mjw.Seat do
  defstruct covered: [], exposed: [], user_id: nil, player_name: nil

  def empty?(%__MODULE__{user_id: nil}), do: true
  def empty?(%__MODULE__{user_id: _}), do: false
end
