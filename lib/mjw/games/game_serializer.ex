defmodule Mjw.Games.GameSerializer do
  @moduledoc """
  Converts between Mjw.Game structs and database-storable maps.
  Handles nested structs (Seat) and recursive structures (undo_state).
  """

  @doc """
  Convert a Game struct to a map suitable for JSON/database storage.
  """

  def to_map(%Mjw.Game{} = game) do
    game
    |> Map.from_struct()
    |> Map.update!(:seats, fn seats ->
      Enum.map(seats, &seat_to_map/1)
    end)
    |> Map.update!(:event_log, fn event_log ->
      Enum.map(event_log, &Tuple.to_list/1)
    end)
    |> Map.update!(:undo_state, fn
      nil -> nil
      %Mjw.Game{} = undo_game -> to_map(undo_game)
    end)
  end

  defp seat_to_map(%Mjw.Seat{} = seat) do
    Map.from_struct(seat)
  end

  @doc """
  Convert a map from the database back to a Game struct.
  """
  def from_map(nil), do: nil

  def from_map(map) when is_map(map) do
    seats =
      map
      |> get_field("seats")
      |> Enum.map(&map_to_seat/1)

    undo_state =
case get_field(map, "undo_state") do
        nil -> nil
        undo_map -> from_map(undo_map)
end

    game_fields =
      map
      |> atomize_keys()
      |> Map.put(:seats, seats)
      |> Map.put(:undo_state, undo_state)
      |> Map.update!(:event_log, fn event_log ->
        Enum.map(event_log, &List.to_tuple/1)
      end)
      |> Map.update!(:turn_state, &to_atom_if_binary/1)

    struct(Mjw.Game, game_fields)
  end

  defp map_to_seat(map) when is_map(map) do
    map
    |> atomize_keys()
    |> Map.update!(:winreaction, &to_atom_if_binary/1)
    |> then(&struct(Mjw.Seat, &1))
  end

  defp to_atom_if_binary(nil), do: nil
  defp to_atom_if_binary(value) when is_atom(value), do: value
  defp to_atom_if_binary(value) when is_binary(value), do: String.to_existing_atom(value)

  # Handles both string keys (from JSON) and atom keys (from Elixir maps)
  defp get_field(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
  end
end
