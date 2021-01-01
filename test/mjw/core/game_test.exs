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
        seats: ~w(0 1 2 3) |> Enum.map(fn i -> %Mjw.Seat{player_id: i} end)
      }

      assert Mjw.Game.empty_seats_count(game) == 0
    end

    test "returns the number of empty seats when partially full" do
      game = %Mjw.Game{
        seats:
          Enum.concat(
            ~w(0 1) |> Enum.map(fn i -> %Mjw.Seat{player_id: i} end),
            ~w(2 3) |> Enum.map(fn _ -> %Mjw.Seat{player_id: nil} end)
          )
      }

      assert Mjw.Game.empty_seats_count(game) == 2
    end
  end

  describe "sitting_at" do
    test "returns the seat number of the player_id, or nil if not sitting" do
      game = %Mjw.Game{
        seats: ~w(0 1 2 3) |> Enum.map(fn i -> %Mjw.Seat{player_id: i} end)
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

  describe "state" do
    test "waiting for players" do
      game = Mjw.Game.new()
      assert Mjw.Game.state(game) == :waiting_for_players
    end

    test "waiting for players when partially filled" do
      game = %Mjw.Game{
        seats:
          Enum.concat(
            ~w(0 1) |> Enum.map(fn i -> %Mjw.Seat{player_id: i, player_name: i} end),
            ~w(2 3) |> Enum.map(fn _ -> %Mjw.Seat{player_id: nil} end)
          )
      }

      assert Mjw.Game.state(game) == :waiting_for_players
    end

    test "picking winds" do
      game = %Mjw.Game{
        seats: ~w(0 1 2 3) |> Enum.map(fn i -> %Mjw.Seat{player_id: i, player_name: i} end)
      }

      assert Mjw.Game.state(game) == :picking_winds
    end
  end

  describe "remaining_winds_to_pick" do
    test "is all winds when no winds are picked" do
      game = %Mjw.Game{}

      assert game |> Mjw.Game.remaining_winds_to_pick() |> Enum.sort() == ~w(🀀 🀁 🀂 🀃)
    end

    test "is empty when all winds are picked" do
      game = %Mjw.Game{
        seats: ~w(🀀 🀁 🀂 🀃) |> Enum.map(fn w -> %Mjw.Seat{picked_wind: w} end)
      }

      assert game |> Mjw.Game.remaining_winds_to_pick() == []
    end

    test "is the remaining winds when winds are partially picked" do
      game = %Mjw.Game{
        seats:
          Enum.concat(
            ~w(🀀 🀃) |> Enum.map(fn w -> %Mjw.Seat{picked_wind: w} end),
            ~w(2 3) |> Enum.map(fn _ -> %Mjw.Seat{} end)
          )
      }

      assert game |> Mjw.Game.remaining_winds_to_pick() |> Enum.sort() == ~w(🀁 🀂)
    end
  end

  describe "pick_random_available_wind" do
    test "picks a random available wind for the given seat number" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.pick_random_available_wind(1)

      wind = Enum.at(game.seats, 1).picked_wind
      assert Enum.member?(~w(🀀 🀁 🀂 🀃), wind)
      assert game.seats |> List.delete_at(1) |> Enum.all?(&(&1.picked_wind == nil))
    end

    test "assigns all winds when run on each seat" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)

      assert game.seats |> Enum.map(& &1.picked_wind) |> Enum.sort() == ~w(🀀 🀁 🀂 🀃)
    end

    test "does nothing if there are no available winds" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)

      old_wind = Enum.at(game.seats, 0).picked_wind
      game |> Mjw.Game.pick_random_available_wind(0)
      new_wind = Enum.at(game.seats, 0).picked_wind
      assert old_wind == new_wind
    end

    test "works if the player already has a wind for some reason" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(0)

      wind = Enum.at(game.seats, 0).picked_wind
      assert game |> Mjw.Game.remaining_winds_to_pick() == ~w(🀀 🀁 🀂 🀃) |> List.delete(wind)
    end
  end
end
