defmodule Mjw.GameTest do
  use ExUnit.Case, async: true

  describe "new" do
    test "generates a Game with reasonable initial values" do
      game = Mjw.Game.new()
      assert game.id =~ ~r/\A[a-f0-9\-]{36}\z/
      assert length(game.deck) == 136
      assert game.wind == "🀀"
      assert game.discards == []
      assert length(game.seats) == 4
    end
  end

  describe "empty_seats_count" do
    test "returns 4 when all seats are empty" do
      game = Mjw.Game.new()
      assert Mjw.Game.empty_seats_count(game) == 4
    end

    test "returns 0 when all seats are full" do
      game = %Mjw.Game{
        seats: 0..3 |> Enum.map(fn i -> %Mjw.Seat{player_id: i} end)
      }

      assert Mjw.Game.empty_seats_count(game) == 0
    end

    test "returns the number of empty seats when partially full" do
      game = %Mjw.Game{
        seats:
          Enum.concat(
            0..1 |> Enum.map(fn i -> %Mjw.Seat{player_id: i} end),
            2..3 |> Enum.map(fn _ -> %Mjw.Seat{player_id: nil} end)
          )
      }

      assert Mjw.Game.empty_seats_count(game) == 2
    end
  end

  describe "sitting_at" do
    test "returns the seat number of the player_id, or nil if not sitting" do
      game = %Mjw.Game{
        seats: 0..3 |> Enum.map(fn i -> %Mjw.Seat{player_id: Integer.to_string(i)} end)
      }

      assert Mjw.Game.sitting_at(game, "0") == 0
      assert Mjw.Game.sitting_at(game, "1") == 1
      assert Mjw.Game.sitting_at(game, "2") == 2
      assert Mjw.Game.sitting_at(game, "3") == 3
      assert Mjw.Game.sitting_at(game, "nonsitter") == nil
    end

    test "returns nil if all seats are empty" do
      game = Mjw.Game.new()

      assert Mjw.Game.sitting_at(game, "any_id") == nil
    end
  end

  describe "seat_player" do
    test "adds a player to the first empty seat" do
      game = %Mjw.Game{
        seats:
          Enum.concat(
            ~w(0 1) |> Enum.map(fn i -> %Mjw.Seat{player_id: i, player_name: i} end),
            ~w(2 3) |> Enum.map(fn _ -> %Mjw.Seat{player_id: nil} end)
          )
      }

      game = game |> Mjw.Game.seat_player("new_id", "New Name")
      assert Enum.map(game.seats, & &1.player_id) == ["0", "1", "new_id", nil]
      assert Enum.map(game.seats, & &1.player_name) == ["0", "1", "New Name", nil]
    end
  end
end
