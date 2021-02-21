defmodule Mjw.GameTest do
  use ExUnit.Case, async: true

  describe "new" do
    test "generates a Game with reasonable initial values" do
      game = Mjw.Game.new()
      assert game.id =~ ~r/\A[a-f0-9\-]{36}\z/
      assert length(game.deck) == 136
      assert game.wind == "we"
      assert game.discards == []
      assert length(game.seats) == 4
    end
  end

  describe "empty?" do
    test "returns true when all seats are empty" do
      game = %Mjw.Game{}
      assert Mjw.Game.empty?(game)
    end

    test "returns false when a seat is filled" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")

      refute Mjw.Game.empty?(game)
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

    test "rolling_for_deal" do
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
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.reseat_players()

      assert Mjw.Game.state(game) == :rolling_for_deal
    end

    test "discarding" do
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
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.reseat_players()
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.deal()

      assert Mjw.Game.state(game) == :discarding
    end

    test "drawing" do
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
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.reseat_players()
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.deal()
        |> Mjw.Game.discard(0, "n1-1")

      assert Mjw.Game.state(game) == :drawing
    end

    test "win_declared" do
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
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.reseat_players()
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.deal()
        |> Mjw.Game.update_wintile(0, "n1-0")

      assert Mjw.Game.state(game) == :win_declared
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
      assert wind in ~w(we ws ww wn)
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

      assert game.seats |> Enum.map(& &1.picked_wind) |> Enum.sort() == ~w(we wn ws ww)
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

  describe "seated_player_names" do
    test "returns empty array when no players are seated" do
      game = %Mjw.Game{}

      assert Mjw.Game.seated_player_names(game) == []
    end

    test "returns the names of all seated players" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")

      assert Mjw.Game.seated_player_names(game) == ["name0", "name1"]
    end
  end

  describe "picked_winds_player_names" do
    test "maps to nils when no winds are picked" do
      game = %Mjw.Game{}

      expected = %{"we" => nil, "ws" => nil, "ww" => nil, "wn" => nil}
      assert game |> Mjw.Game.picked_winds_player_names() == expected
    end

    test "maps the winds to the players who picked them" do
      game = %Mjw.Game{
        seats:
          ~w(we ws ww wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_name: "name#{i}"}
          end)
      }

      expected = %{"we" => "name0", "ws" => "name1", "ww" => "name2", "wn" => "name3"}
      assert game |> Mjw.Game.picked_winds_player_names() == expected
    end
  end

  describe "roll_dice" do
    test "sets dice to 3 random dice" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.roll_dice()

      assert length(game.dice) == 3
      dice_total = game.dice |> Enum.sum()
      assert dice_total >= 1 * 3
      assert dice_total <= 6 * 3
    end
  end

  describe "reseat_players" do
    test "reseats the players according to the roll and the picked winds" do
      game =
        %Mjw.Game{
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{picked_wind: w, player_id: "id#{i}", player_name: "name#{i}"}
            end),
          dice: [1, 1, 6]
        }
        |> Mjw.Game.reseat_players()

      assert game.seats |> Enum.map(& &1.player_id) == ~w(id3 id1 id2 id0)
    end
  end

  describe "find_picked_wind_seat" do
    test "returns the seat that has the given picked_wind" do
      game = %Mjw.Game{
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_id: "id#{i}", player_name: "name#{i}"}
          end)
      }

      assert Mjw.Game.find_picked_wind_seat(game, "ws").player_id == "id2"
    end
  end

  describe "deal" do
    test "deals the deck, sets dealpick_seatno, changes turn_state to discarding" do
      game =
        %{
          Mjw.Game.new()
          | dealer_seatno: 1,
            turn_seatno: 1,
            dice: [1, 2, 3],
            seats: 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)
        }
        |> Mjw.Game.deal()

      assert game.seats |> Enum.map(&length(&1.concealed)) == [13, 14, 13, 13]
      assert length(game.deck) == 83
      assert game.turn_state == :discarding
      assert game.dealpick_seatno == 2
    end
  end

  describe "roller_seat_with_relative_position" do
    test "uses the player who picked the East wind when rolling for first dealer" do
      game = %Mjw.Game{
        turn_seatno: 0,
        dealer_seatno: 0,
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_id: "id#{i}", player_name: "name#{i}"}
          end)
      }

      {roller_seat, relative_position} =
        Mjw.Game.roller_seat_with_relative_position(game, :rolling_for_first_dealer, 3)

      assert roller_seat.player_id == "id1"
      assert relative_position == 2
    end

    test "uses dealer_seatno when rolling for deal" do
      game = %Mjw.Game{
        turn_seatno: 0,
        dealer_seatno: 0,
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_id: "id#{i}", player_name: "name#{i}"}
          end)
      }

      {roller_seat, relative_position} =
        Mjw.Game.roller_seat_with_relative_position(game, :rolling_for_deal, 3)

      assert roller_seat.player_id == "id0"
      assert relative_position == 1
    end
  end

  describe "discard" do
    test "adds tile to discards, removes from player's hand, and changes turn to the next player" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          seats:
            0..3
            |> Enum.map(fn i ->
              %Mjw.Seat{concealed: ["c1-#{i}", "c2-#{i}", "c3-#{i}", "c4-#{i}"]}
            end)
        }
        |> Mjw.Game.discard(3, "c2-3")

      assert game.discards == ["c2-3", "dp-0"]
      assert game.turn_state == :drawing
      assert game.turn_seatno == 0
      assert game.prev_turn_seatno == 3
      assert game.seats |> Enum.at(3) |> Map.get(:concealed) == ["c1-3", "c3-3", "c4-3"]
    end
  end

  describe "update_concealed" do
    test "changes the concealed tiles for the given seat number" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.update_concealed(1, ["dp-0", "c1-3"])

      assert game.seats |> Enum.map(& &1.concealed) == [[], ["dp-0", "c1-3"], [], []]
    end
  end

  describe "update_exposed" do
    test "changes the exposed tiles for the given seat number" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.update_exposed(1, ["dp-0", "c1-3"])

      assert game.seats |> Enum.map(& &1.exposed) == [[], ["dp-0", "c1-3"], [], []]
    end
  end

  describe "update_hiddengongs" do
    test "changes the hidden gongs for the given seat number" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.update_hiddengongs(1, ["dp-0", "c1-3"])

      assert game.seats |> Enum.map(& &1.hidden_gongs) == [[], ["dp-0", "c1-3"], [], []]
    end
  end

  describe "update_wintile" do
    test "updates the winning tile for the given seat number" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.update_wintile(1, "n9-1")

      assert game.seats |> Enum.map(& &1.wintile) == [nil, "n9-1", nil, nil]
      assert game.seats |> Enum.map(& &1.winreaction) == [nil, :ok, nil, nil]
    end
  end

  describe "update_wintile_from_discards" do
    test "updates the winning tile for the given seat number and removes it from discards" do
      game =
        %Mjw.Game{discards: ["n1-0", "n2-0", "n3-0"]}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.update_wintile_from_discards(1, "n1-0")

      assert game.seats |> Enum.map(& &1.wintile) == [nil, "n1-0", nil, nil]
      assert game.seats |> Enum.map(& &1.winreaction) == [nil, :ok, nil, nil]
      assert game.discards == ["n2-0", "n3-0"]
    end
  end

  describe "draw_discard" do
    test "when it's not a pong, removes the tile from discards and updates the player's exposed & turn state" do
      {event, game} =
        %Mjw.Game{
          turn_seatno: 3,
          prev_turn_seatno: 2,
          turn_state: :drawing,
          discards: ["dp-0", "df-0", "dp-1"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.draw_discard(3, ["c1-0", "c1-1", "dp-0", "c2-0"])

      assert event == :drew_discard
      assert game.discards == ["df-0", "dp-1"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 3
      assert game.prev_turn_seatno == 2
      assert game.seats |> Enum.at(3) |> Map.get(:exposed) == ["c1-0", "c1-1", "dp-0", "c2-0"]
    end

    test "when it's a pong, removes the tile from discards and updates the player's exposed, turn state, and turn" do
      {event, game} =
        %Mjw.Game{
          turn_seatno: 3,
          prev_turn_seatno: 2,
          turn_state: :drawing,
          discards: ["dp-0", "df-0", "dp-1"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.draw_discard(0, ["c1-0", "c1-1", "dp-0", "c2-0"])

      assert event == :ponged
      assert game.discards == ["df-0", "dp-1"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 0
      assert game.prev_turn_seatno == 3
      assert game.seats |> Enum.at(0) |> Map.get(:exposed) == ["c1-0", "c1-1", "dp-0", "c2-0"]
    end
  end

  describe "draw_from_deck" do
    test "removes a tile from deck, updates the player's concealed, updates turn state" do
      {game, returned_tile} =
        %Mjw.Game{
          turn_seatno: 3,
          prev_turn_seatno: 2,
          turn_state: :drawing,
          deck: ["dp-0", "df-0", "dp-1"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.draw_from_deck(3, ["c1-0", "c1-1", "decktile", "c2-0"])

      assert game.deck == ["df-0", "dp-1"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 3
      assert game.prev_turn_seatno == 2
      assert game.seats |> Enum.at(3) |> Map.get(:concealed) == ["c1-0", "c1-1", "dp-0", "c2-0"]
      assert returned_tile == "dp-0"
    end
  end

  describe "draw_correction_tile" do
    test "removes a tile from deck and updates the player's concealed tiles" do
      {game, returned_tile} =
        %Mjw.Game{
          turn_seatno: 3,
          prev_turn_seatno: 2,
          turn_state: :discarding,
          deck: ["dp-0", "df-0", "dp-1"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.draw_correction_tile(0, ["c1-0", "c1-1", "decktile", "c2-0"])

      assert game.deck == ["df-0", "dp-1"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 3
      assert game.prev_turn_seatno == 2
      assert game.seats |> Enum.at(0) |> Map.get(:concealed) == ["c1-0", "c1-1", "dp-0", "c2-0"]
      assert returned_tile == "dp-0"
    end
  end

  describe "turn_player_name" do
    test "returns the name of the player whose turn it is" do
      game =
        %Mjw.Game{
          turn_seatno: 2,
          turn_state: :drawing
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      assert Mjw.Game.turn_player_name(game) == "name2"
    end

    test "returns empty string if seat is empty" do
      game =
        %Mjw.Game{
          turn_seatno: 2,
          turn_state: :drawing
        }
        |> Mjw.Game.seat_player("id0", "name0")

      assert Mjw.Game.turn_player_name(game) == ""
    end
  end

  describe "evacuate_seat" do
    test "removes a player from the given seatno" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.evacuate_seat(1)

      assert Enum.map(game.seats, & &1.player_id) == ["id0", nil, "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", nil, "name2", "name3"]
    end
  end

  describe "reset" do
    test "resets the game except for player info" do
      orig_game = %Mjw.Game{
        id: "6c1d42d8-28db-4b3b-a3f2-976d854e0394",
        dealer_seatno: 1,
        dealer_win_count: 1,
        turn_seatno: 3,
        prev_turn_seatno: 2,
        turn_state: :discarding,
        deck: ["dp-1"],
        discards: ["dp-0"],
        dice: [1, 2, 3],
        wind: "wn",
        seats:
          0..3
          |> Enum.map(fn i ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: "ww",
              concealed: ["n1-#{i}"],
              exposed: ["n2-#{i}"],
              hidden_gongs: ["n3-#{i}"],
              wintile: "n4-#{i}",
              winreaction: :ok
            }
          end)
      }

      game = Mjw.Game.reset(orig_game)

      assert game.id == orig_game.id
      assert length(game.deck) == 136
      assert game.discards == []
      assert game.dice == []
      assert game.wind == "we"
      assert game.turn_state == :rolling
      assert game.dealer_seatno == 0
      assert game.dealer_win_count == 0
      assert game.turn_seatno == 0
      assert game.prev_turn_seatno == 0
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hidden_gongs) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.wintile) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.winreaction) == [nil, nil, nil, nil]
    end
  end

  describe "draw" do
    test "advances the game to the next round without changing dealer" do
      game =
        %Mjw.Game{
          deck: ["dp-1"],
          discards: ["dp-0"],
          dice: [1, 2, 3],
          dealer_seatno: 1,
          dealer_win_count: 1,
          turn_seatno: 3,
          prev_turn_seatno: 2,
          turn_state: :discarding,
          wind: "wn",
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{
                player_id: "id#{i}",
                player_name: "name#{i}",
                picked_wind: w,
                concealed: ["n1-#{i}"],
                exposed: ["n2-#{i}"],
                hidden_gongs: ["n3-#{i}"],
                wintile: "n4-#{i}",
                winreaction: :ok
              }
            end)
        }
        |> Mjw.Game.draw()

      assert length(game.deck) == 136
      assert game.discards == []
      assert game.wind == "wn"
      assert game.turn_state == :rolling
      assert game.dealer_seatno == 1
      assert game.dealer_win_count == 2
      assert game.turn_seatno == 1
      assert game.prev_turn_seatno == 3
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == ~w(ww we ws wn)
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hidden_gongs) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.wintile) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.winreaction) == [nil, nil, nil, nil]
      assert Mjw.Game.state(game) == :rolling_for_deal
    end
  end

  describe "dq" do
    test "DQing a non-dealer behaves like draw" do
      game =
        %Mjw.Game{
          deck: ["dp-1"],
          discards: ["dp-0"],
          dice: [1, 2, 3],
          dealer_seatno: 1,
          dealer_win_count: 1,
          turn_seatno: 3,
          prev_turn_seatno: 2,
          turn_state: :discarding,
          wind: "wn",
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{
                player_id: "id#{i}",
                player_name: "name#{i}",
                picked_wind: w,
                concealed: ["n1-#{i}"],
                exposed: ["n2-#{i}"],
                hidden_gongs: ["n3-#{i}"],
                wintile: "n4-#{i}",
                winreaction: :ok
              }
            end)
        }
        |> Mjw.Game.dq(3)

      assert length(game.deck) == 136
      assert game.discards == []
      assert game.wind == "wn"
      assert game.turn_state == :rolling
      assert game.dealer_seatno == 1
      assert game.dealer_win_count == 2
      assert game.turn_seatno == 1
      assert game.prev_turn_seatno == 3
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == ~w(ww we ws wn)
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hidden_gongs) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.wintile) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.winreaction) == [nil, nil, nil, nil]
      assert Mjw.Game.state(game) == :rolling_for_deal
    end

    test "DQing a dealer advances the dealer" do
      game =
        %Mjw.Game{
          deck: ["dp-1"],
          discards: ["dp-0"],
          dice: [1, 2, 3],
          dealer_seatno: 3,
          dealer_win_count: 1,
          turn_seatno: 2,
          prev_turn_seatno: 1,
          turn_state: :discarding,
          wind: "wn",
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{
                player_id: "id#{i}",
                player_name: "name#{i}",
                picked_wind: w,
                concealed: ["n1-#{i}"],
                exposed: ["n2-#{i}"],
                hidden_gongs: ["n3-#{i}"],
                wintile: "n4-#{i}",
                winreaction: :ok
              }
            end)
        }
        |> Mjw.Game.dq(3)

      assert length(game.deck) == 136
      assert game.discards == []
      assert game.wind == "we"
      assert game.turn_state == :rolling
      assert game.dealer_seatno == 0
      assert game.dealer_win_count == 0
      assert game.turn_seatno == 0
      assert game.prev_turn_seatno == 2
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == ~w(ww we ws wn)
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hidden_gongs) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.wintile) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.winreaction) == [nil, nil, nil, nil]
      assert Mjw.Game.state(game) == :rolling_for_deal
    end
  end

  describe "win_declared_seatno" do
    test "returns the seatno of the declared winner" do
      seatno =
        %Mjw.Game{
          seats: [
            %Mjw.Seat{},
            %Mjw.Seat{},
            %Mjw.Seat{wintile: "n1-1", winreaction: :ok},
            %Mjw.Seat{}
          ]
        }
        |> Mjw.Game.win_declared_seatno()

      assert seatno == 2
    end

    test "returns nil if no declared winner" do
      seatno =
        %Mjw.Game{
          seats: 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)
        }
        |> Mjw.Game.win_declared_seatno()

      assert seatno == nil
    end
  end

  describe "confirm_win" do
    test "one player confirms another player's declared win" do
      game =
        %Mjw.Game{
          deck: ["dp-1"],
          discards: ["dp-0"],
          turn_state: :discarding,
          turn_seatno: 2,
          dealer_seatno: 0,
          dealer_win_count: 1,
          seats: [
            %Mjw.Seat{winreaction: nil},
            %Mjw.Seat{winreaction: nil},
            %Mjw.Seat{wintile: "n1-1", winreaction: :ok},
            %Mjw.Seat{winreaction: :expose}
          ]
        }
        |> Mjw.Game.confirm_win(3)

      assert game.seats |> Enum.map(& &1.winreaction) == [nil, nil, :ok, :expose_ok]
      assert game.deck == ["dp-1"]
      assert game.discards == ["dp-0"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 2
      assert game.dealer_seatno == 0
      assert game.dealer_win_count == 1
    end

    test "advances the game if all players confirmed the win (non-dealer winner)" do
      game =
        %Mjw.Game{
          deck: ["dp-1"],
          discards: ["dp-0"],
          turn_state: :discarding,
          turn_seatno: 1,
          dealer_seatno: 3,
          dealer_win_count: 1,
          wind: "we",
          seats: [
            %Mjw.Seat{winreaction: :ok},
            %Mjw.Seat{winreaction: :expose_ok},
            %Mjw.Seat{wintile: "n1-1", winreaction: :ok},
            %Mjw.Seat{winreaction: :expose}
          ]
        }
        |> Mjw.Game.confirm_win(3)

      assert game.seats |> Enum.map(& &1.winreaction) == [nil, nil, nil, nil]
      assert game.seats |> Enum.map(& &1.wintile) == [nil, nil, nil, nil]
      assert length(game.deck) == 136
      assert game.discards == []
      assert game.turn_state == :rolling
      assert game.prev_turn_seatno == 1
      assert game.turn_seatno == 0
      assert game.dealer_seatno == 0
      assert game.dealer_win_count == 0
      assert game.wind == "ws"
    end

    test "advances the game if all players confirmed the win (dealer wins)" do
      game =
        %Mjw.Game{
          deck: ["dp-1"],
          discards: ["dp-0"],
          turn_state: :discarding,
          turn_seatno: 1,
          dealer_seatno: 3,
          dealer_win_count: 1,
          wind: "we",
          seats: [
            %Mjw.Seat{winreaction: :ok},
            %Mjw.Seat{winreaction: :expose_ok},
            %Mjw.Seat{winreaction: :expose},
            %Mjw.Seat{wintile: "n1-1", winreaction: :ok}
          ]
        }
        |> Mjw.Game.confirm_win(2)

      assert game.seats |> Enum.map(& &1.winreaction) == [nil, nil, nil, nil]
      assert game.seats |> Enum.map(& &1.wintile) == [nil, nil, nil, nil]
      assert length(game.deck) == 136
      assert game.discards == []
      assert game.turn_state == :rolling
      assert game.turn_seatno == 3
      assert game.prev_turn_seatno == 1
      assert game.dealer_seatno == 3
      assert game.dealer_win_count == 2
      assert game.wind == "we"
    end
  end

  describe "expose_loser_hand" do
    test "confirms another player's declared win" do
      game =
        %Mjw.Game{
          seats: [
            %Mjw.Seat{winreaction: nil},
            %Mjw.Seat{winreaction: nil},
            %Mjw.Seat{wintile: "n1-1", winreaction: :ok},
            %Mjw.Seat{winreaction: :ok}
          ]
        }
        |> Mjw.Game.expose_loser_hand(3)

      assert game.seats |> Enum.map(& &1.winreaction) == [nil, nil, :ok, :expose_ok]
    end
  end

  describe "confirmed_win?" do
    test "false if not all seats confirmed the declared win" do
      game = %Mjw.Game{
        seats: [
          %Mjw.Seat{winreaction: :ok},
          %Mjw.Seat{winreaction: :expose_ok},
          %Mjw.Seat{wintile: "n1-1", winreaction: :ok},
          %Mjw.Seat{winreaction: :ok}
        ]
      }

      assert game |> Mjw.Game.confirmed_win?()
    end

    test "true if all seats confirmed the declared win" do
      game = %Mjw.Game{
        seats: [
          %Mjw.Seat{winreaction: :ok},
          %Mjw.Seat{winreaction: :expose},
          %Mjw.Seat{wintile: "n1-1", winreaction: :ok},
          %Mjw.Seat{winreaction: :ok}
        ]
      }

      refute game |> Mjw.Game.confirmed_win?()
    end
  end

  describe "replace_seat" do
    test "Completely replaces the given seatno" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "Name0")
        |> Mjw.Game.seat_player("id1", "Name1")
        |> Mjw.Game.replace_seat(0, %Mjw.Seat{player_id: "id2", player_name: "Name2"})

      assert game.seats |> Enum.map(& &1.player_id) == ["id2", "id1", nil, nil]
      assert game.seats |> Enum.map(& &1.player_name) == ["Name2", "Name1", nil, nil]
    end
  end
end
