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
      game = %Mjw.Game{}
      assert Mjw.Game.empty_seats_count(game) == 4
    end

    test "returns 0 when all seats are full" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      assert Mjw.Game.empty_seats_count(game) == 0
    end

    test "returns the number of empty seats when partially full" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")

      assert Mjw.Game.empty_seats_count(game) == 3
    end
  end

  describe "sitting_at" do
    test "returns the seat number of the player_id, or nil if not sitting" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      assert game |> Mjw.Game.sitting_at("id0") == 0
      assert game |> Mjw.Game.sitting_at("id1") == 1
      assert game |> Mjw.Game.sitting_at("id2") == 2
      assert game |> Mjw.Game.sitting_at("id3") == 3
      assert game |> Mjw.Game.sitting_at("nonsitter") == nil
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
    test "waiting_for_players" do
      game = Mjw.Game.new()
      assert Mjw.Game.state(game) == :waiting_for_players
    end

    test "waiting for players when partially filled" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")

      assert Mjw.Game.state(game) == :waiting_for_players
    end

    test "picking_winds" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      assert Mjw.Game.state(game) == :picking_winds
    end

    test "rolling_for_first_dealer" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind("id0", 0)
        |> Mjw.Game.pick_random_available_wind("id1", 0)
        |> Mjw.Game.pick_random_available_wind("id2", 0)
        |> Mjw.Game.pick_random_available_wind("id3", 0)

      assert Mjw.Game.state(game) == :rolling_for_first_dealer
    end
  end

  describe "pick_random_available_wind" do
    test "picks a random available wind for the given player" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind("id1", 3)

      wind = game |> Mjw.Game.picked_wind("id1")
      assert Enum.member?(~w(🀀 🀁 🀂 🀃), wind)
      assert game |> Mjw.Game.picked_wind("id0") == nil
      assert game |> Mjw.Game.picked_wind_idx("id1") == 3
      assert game |> Mjw.Game.picked_wind_idx("id0") == nil
    end

    test "assigns all winds when run for each player" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind("id0", 0)
        |> Mjw.Game.pick_random_available_wind("id1", 0)
        |> Mjw.Game.pick_random_available_wind("id2", 0)
        |> Mjw.Game.pick_random_available_wind("id3", 0)

      assert game.seats |> Enum.map(& &1.picked_wind) |> Enum.sort() == ~w(🀀 🀁 🀂 🀃)
      assert game.seats |> Enum.map(& &1.picked_wind_idx) == [0, 0, 0, 0]
    end

    test "does nothing if there are no available winds" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind("id0", 0)
        |> Mjw.Game.pick_random_available_wind("id1", 0)
        |> Mjw.Game.pick_random_available_wind("id2", 0)
        |> Mjw.Game.pick_random_available_wind("id3", 0)

      old_wind =
        game
        |> Mjw.Game.picked_wind("id0")

      new_wind =
        game
        |> Mjw.Game.pick_random_available_wind("id0", 1)
        |> Mjw.Game.picked_wind("id0")

      assert old_wind == new_wind
    end

    test "works if the player already has a wind for some reason" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.pick_random_available_wind("id0", 0)
        |> Mjw.Game.pick_random_available_wind("id0", 3)

      assert game |> Mjw.Game.picked_wind("id0")
      assert game |> Mjw.Game.picked_wind_idx("id0") == 3
    end
  end

  describe "picked_winds_player_names" do
    test "maps to nils when no winds are picked" do
      game = %Mjw.Game{}

      expected = %{"🀀" => nil, "🀁" => nil, "🀂" => nil, "🀃" => nil}
      assert game |> Mjw.Game.picked_winds_player_names() == expected
    end

    test "maps the winds to the players who picked them" do
      game = %Mjw.Game{
        seats:
          ~w(🀀 🀁 🀂 🀃)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_name: "name#{Integer.to_string(i)}"}
          end)
      }

      expected = %{"🀀" => "name0", "🀁" => "name1", "🀂" => "name2", "🀃" => "name3"}
      assert game |> Mjw.Game.picked_winds_player_names() == expected
    end
  end
end
