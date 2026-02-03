defmodule Mjw.Games.GameSerializer do
  @moduledoc """
  Converts between Game structs and database-storable maps.
  Handles nested structs (Seat) and recursive structures (undo_state).
  """

  alias Mjw.Games.{Game, Seat}

  # Allowed atom keys and values are defined in Game and Seat modules

  @doc """
  Convert a Game struct to a map suitable for JSON/database storage.
  """
  def to_map(%Game{} = game) do
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
      %Game{} = undo_game -> to_map(undo_game)
    end)
  end

  defp seat_to_map(%Seat{} = seat) do
    Map.from_struct(seat)
  end

  @doc """
  Convert a map from the database back to a Game struct.
  """
  def from_map(nil), do: nil

  def from_map(map) when is_map(map) do
    seats = map |> get_field("seats") |> Enum.map(&map_to_seat/1)
    undo_state = get_field(map, "undo_state") |> from_map

    game_fields =
      map
      |> atomize_keys(Game.fields())
      |> Map.merge(%{seats: seats, undo_state: undo_state})
      |> Map.update!(:event_log, fn event_log ->
        Enum.map(event_log, &List.to_tuple/1)
      end)
      |> Map.update!(:turn_state, &to_atom_if_binary(&1, Game.turn_states()))

    struct(Game, game_fields)
  end

  defp map_to_seat(map) when is_map(map) do
    map
    |> atomize_keys(Seat.fields())
    |> Map.update!(:winreaction, &to_atom_if_binary(&1, Seat.winreactions()))
    |> then(&struct(Seat, &1))
  end

  defp to_atom_if_binary(nil, _allowed), do: nil
  defp to_atom_if_binary(value, _allowed) when is_atom(value), do: value

  defp to_atom_if_binary(value, allowed) when is_binary(value) do
    atom = String.to_atom(value)

    if atom in allowed do
      atom
    else
      raise ArgumentError, "Invalid atom value: #{inspect(value)}"
    end
  end

  # Handles both string keys (from JSON) and atom keys (from Elixir maps)
  defp get_field(map, key) when is_binary(key) do
    Map.get(map, key) || Map.get(map, String.to_atom(key))
  end

  defp atomize_keys(map, allowed_keys) when is_map(map) do
    allowed_key_strings = Enum.map(allowed_keys, &Atom.to_string/1)

    Map.new(map, fn
      {k, v} when is_binary(k) ->
        if k in allowed_key_strings do
          {String.to_atom(k), v}
        else
          raise ArgumentError, "Invalid key: #{inspect(k)}"
        end

      {k, v} when is_atom(k) ->
        if k in allowed_keys do
          {k, v}
        else
          raise ArgumentError, "Invalid key: #{inspect(k)}"
        end
    end)
  end
end
