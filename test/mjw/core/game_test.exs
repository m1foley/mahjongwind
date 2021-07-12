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
      game =
        %Mjw.Game{
          seats:
            Enum.concat(
              ~w(0 1) |> Enum.map(fn i -> %Mjw.Seat{player_id: i, player_name: i} end),
              ~w(2 3) |> Enum.map(fn _ -> %Mjw.Seat{player_id: nil} end)
            )
        }
        |> Mjw.Game.seat_player("new_id", "New Name")

      assert Enum.map(game.seats, & &1.player_id) == ["0", "1", "new_id", nil]
      assert Enum.map(game.seats, & &1.player_name) == ["0", "1", "New Name", nil]
    end

    test "does nothing if no empty seats" do
      orig_game = %Mjw.Game{
        seats:
          ~w(we ws ww wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_id: "id#{i}", player_name: "name#{i}"}
          end)
      }

      game = orig_game |> Mjw.Game.seat_player("id1", "Won't Get Seated")
      assert game == orig_game
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
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)

      assert Mjw.Game.state(game) == :rolling_for_first_dealer
    end

    test "rolling_for_deal" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
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
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.reseat_players()
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.deal()

      assert Mjw.Game.state(game) == :discarding
    end

    test "drawing" do
      {:ok, game} =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
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
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.reseat_players()
        |> Mjw.Game.roll_dice()
        |> Mjw.Game.deal()
        |> Mjw.Game.declare_win_from_hand(0, "n1-0")

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
        |> Mjw.Game.pick_random_available_wind(1, 2)

      assert Mjw.Game.picked_wind(game, "id0") == nil
      assert Mjw.Game.picked_wind(game, "id1") in ~w(we ws ww wn)
      assert Mjw.Game.picked_wind_idx(game, "id0") == nil
      assert Mjw.Game.picked_wind_idx(game, "id1") == 2
    end

    test "uses a default value for picked_wind_idx" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(1)

      assert Mjw.Game.picked_wind(game, "id0") == nil
      assert Mjw.Game.picked_wind(game, "id1") in ~w(we ws ww wn)
      assert Mjw.Game.picked_wind_idx(game, "id0") == nil
      assert Mjw.Game.picked_wind_idx(game, "id1") in 0..3
    end

    test "assigns all winds when run for each player" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0, 0)
        |> Mjw.Game.pick_random_available_wind(1, 0)
        |> Mjw.Game.pick_random_available_wind(2, 0)
        |> Mjw.Game.pick_random_available_wind(3, 0)

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
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)

      old_wind = game |> Mjw.Game.picked_wind("id0")

      new_wind =
        game
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.picked_wind("id0")

      assert old_wind == new_wind
    end

    test "works if the player already has a wind for some reason" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.pick_random_available_wind(0, 0)
        |> Mjw.Game.pick_random_available_wind(0, 3)

      assert Mjw.Game.picked_wind(game, "id0") in ~w(we ws ww wn)
      assert Mjw.Game.picked_wind_idx(game, "id0") == 3
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
      assert dice_total >= 3
      assert dice_total <= 18
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

  describe "current_or_most_recent_roller_seat_with_relative_position" do
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
        Mjw.Game.current_or_most_recent_roller_seat_with_relative_position(
          game,
          :rolling_for_first_dealer,
          3
        )

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
        Mjw.Game.current_or_most_recent_roller_seat_with_relative_position(
          game,
          :rolling_for_deal,
          3
        )

      assert roller_seat.player_id == "id0"
      assert relative_position == 1
    end
  end

  describe "current_roller_seatno" do
    test "returns current roller seatno when in rolling_for_first_dealer state" do
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

      assert Mjw.Game.current_roller_seatno(game, :rolling_for_first_dealer) == 1
    end

    test "returns current roller seatno when in rolling_for_deal state" do
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

      assert Mjw.Game.current_roller_seatno(game, :rolling_for_deal) == 0
    end

    test "returns nil when in a non-rolling state" do
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

      assert Mjw.Game.current_roller_seatno(game, :discarding) == nil
    end
  end

  describe "discard" do
    test "moves tile to discards and changes turn to the next player" do
      {:ok, game} =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          deck: ["wn-1"],
          seats:
            0..3
            |> Enum.map(fn i ->
              %Mjw.Seat{
                player_name: "Player #{i}",
                concealed: ["c1-#{i}", "c2-#{i}", "c3-#{i}", "c4-#{i}"]
              }
            end)
        }
        |> Mjw.Game.discard(3, "c2-3")

      assert game.discards == ["c2-3", "dp-0"]
      assert game.turn_state == :drawing
      assert game.turn_seatno == 0
      assert Enum.at(game.seats, 3).concealed == ["c1-3", "c3-3", "c4-3"]
      assert game.event_log == [{"Player 3 discarded.", "c2-3"}]
      assert game.undo_seatno == 3
      assert game.undo_state.turn_seatno == 3
    end

    test "discarding from exposed" do
      {:ok, game} =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          deck: ["wn-1"],
          discards: ["dp-0"],
          seats:
            0..3
            |> Enum.map(fn i ->
              %Mjw.Seat{
                player_name: "Player #{i}",
                concealed: ["c1-#{i}", "c2-#{i}"],
                exposed: ["b1-#{i}", "b2-#{i}"]
              }
            end)
        }
        |> Mjw.Game.discard(3, "b1-3")

      assert game.discards == ["b1-3", "dp-0"]
      assert game.turn_state == :drawing
      assert game.turn_seatno == 0
      assert Enum.at(game.seats, 3).concealed == ["c1-3", "c2-3"]
      assert Enum.at(game.seats, 3).exposed == ["b2-3"]
      assert game.event_log == [{"Player 3 discarded.", "b1-3"}]
      assert game.undo_seatno == 3
      assert game.undo_state.turn_seatno == 3
    end

    test "discarding from concealed when peektile is present" do
      {:ok, game} =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          deck: ["wn-0"],
          seats:
            0..3
            |> Enum.map(fn i ->
              %Mjw.Seat{
                player_name: "Player #{i}",
                concealed: ["c1-#{i}", "c2-#{i}", "c3-#{i}", "c4-#{i}"],
                peektile: "n1-#{i}"
              }
            end)
        }
        |> Mjw.Game.discard(3, "c2-3")

      assert game.discards == ["c2-3", "dp-0"]
      assert game.turn_state == :drawing
      assert game.turn_seatno == 0
      assert Enum.at(game.seats, 3).concealed == ["c1-3", "c3-3", "c4-3", "n1-3"]
      assert Enum.at(game.seats, 3).peektile == nil
      assert game.event_log == [{"Player 3 discarded.", "c2-3"}]
      assert game.undo_seatno == 3
      assert game.undo_state.turn_seatno == 3
    end

    test "declares draw if the deck is empty" do
      {:declared_draw, game} =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          dealer_seatno: 1,
          discards: ["dp-0"],
          deck: [],
          dice: [1, 2, 3],
          wind: "wn",
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{
                player_id: "id#{i}",
                player_name: "Player #{i}",
                picked_wind: w,
                concealed: ["c1-#{i}", "c2-#{i}", "c3-#{i}", "c4-#{i}"]
              }
            end)
        }
        |> Mjw.Game.discard(3, "c2-3")

      assert length(game.deck) == 136
      assert game.discards == []
      assert game.wind == "wn"
      assert game.turn_state == :rolling
      assert game.dealer_seatno == 1
      assert game.dealer_win_count == 1
      assert game.turn_seatno == 1
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log == [{"The game was declared a draw.", "🤝"}]
      assert Mjw.Game.state(game) == :rolling_for_deal
    end
  end

  describe "bot_discard" do
    test "discards a concealed tile and advances turn" do
      {:ok, game} =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          deck: ["wn-0"],
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{seat | concealed: ["b1-0", "b1-1", "n1-1", "c1-0", "c1-1"]}
          end)
        end)
        |> Mjw.Game.bot_discard()

      assert length(game.discards) == 2
      assert game.turn_state == :drawing
      assert game.turn_seatno == 0
      assert game.undo_seatno == 2
      bot_seat = Enum.at(game.seats, 3)
      assert length(bot_seat.concealed) == 4

      assert game.event_log |> Enum.at(0) |> Kernel.elem(0) ==
               "#{bot_seat.player_name} discarded."
    end

    test "declares draw if the deck is empty" do
      {:declared_draw, game} =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          deck: [],
          wind: "wn",
          dice: [1, 2, 3],
          dealer_seatno: 1,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{seat | concealed: ["b1-0", "b1-1", "n1-1", "c1-0", "c1-1"]}
          end)
        end)
        |> Mjw.Game.bot_discard()

      assert length(game.deck) == 136
      assert game.discards == []
      assert game.wind == "wn"
      assert game.turn_state == :rolling
      assert game.dealer_seatno == 1
      assert game.dealer_win_count == 1
      assert game.turn_seatno == 1
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log == [{"The game was declared a draw.", "🤝"}]
      assert Mjw.Game.state(game) == :rolling_for_deal
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

      assert game.seats |> Enum.map(& &1.hiddengongs) == [[], ["dp-0", "c1-3"], [], []]
    end
  end

  describe "declare_win_from_hand" do
    test "declare win" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :drawing,
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{
                player_id: "id#{i}",
                player_name: "name#{i}",
                picked_wind: w,
                concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
              }
            end)
        }
        |> Mjw.Game.declare_win_from_hand(1, "n2-1")

      assert game.seats |> Enum.map(& &1.wintile) == [nil, "n2-1", nil, nil]
      assert game.seats |> Enum.map(&Mjw.Seat.declared_win?/1) == [false, true, false, false]
      assert Enum.at(game.seats, 1).concealed == ["n1-1", "n3-1"]
      assert game.turn_seatno == 1
      assert game.turn_state == :discarding
      assert game.event_log == [{"name1 went out!", "n2-1"}]
      assert game.undo_seatno == 1
      assert game.undo_state.turn_seatno == 3
    end

    test "ensures there is no dangling peektile" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :drawing,
          seats:
            ~w(ww we ws wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{
                player_id: "id#{i}",
                player_name: "name#{i}",
                picked_wind: w,
                concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"],
                peektile: "n4-#{i}"
              }
            end)
        }
        |> Mjw.Game.declare_win_from_hand(1, "n2-1")

      assert game.seats |> Enum.map(& &1.wintile) == [nil, "n2-1", nil, nil]
      assert game.seats |> Enum.map(&Mjw.Seat.declared_win?/1) == [false, true, false, false]
      assert Enum.at(game.seats, 1).concealed == ["n1-1", "n3-1", "n4-1"]
      assert Enum.at(game.seats, 1).peektile == nil
      assert game.turn_seatno == 1
      assert game.turn_state == :discarding
      assert game.event_log == [{"name1 went out!", "n2-1"}]
      assert game.undo_seatno == 1
      assert game.undo_state.turn_seatno == 3
    end
  end

  describe "declare_win_from_discards" do
    test "updates the winning tile for the given seat number and removes it from discards" do
      game =
        %Mjw.Game{
          discards: ["n1-0", "n2-0", "n3-0"],
          turn_seatno: 3,
          turn_state: :drawing
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.declare_win_from_discards(1, "n1-0")

      assert game.seats |> Enum.map(& &1.wintile) == [nil, "n1-0", nil, nil]
      assert game.seats |> Enum.map(& &1.winreaction) == [nil, :expose, nil, nil]
      assert game.discards == ["n2-0", "n3-0"]
      assert game.turn_seatno == 1
      assert game.turn_state == :discarding
      assert game.event_log |> Enum.at(0) == {"name1 went out!", "n1-0"}
      assert game.undo_seatno == 1
      assert game.undo_state.turn_seatno == 3
    end
  end

  describe "bot_declare_win_from_discards" do
    test "updates the winning tile for the given seat number and removes it from discards" do
      game =
        %Mjw.Game{
          discards: ["n1-0", "n2-0", "n3-0"],
          turn_seatno: 3,
          turn_state: :drawing,
          undo_seatno: 1
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 2, fn seat -> %{seat | player_name: "Mr. Bot"} end)
        end)
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.bot_declare_win_from_discards(2)

      assert game.seats |> Enum.map(& &1.wintile) == [nil, nil, "n1-0", nil]
      assert game.seats |> Enum.map(& &1.winreaction) == [nil, nil, :expose, nil]
      assert game.discards == ["n2-0", "n3-0"]
      assert game.turn_seatno == 2
      assert game.turn_state == :discarding
      assert game.event_log |> Enum.at(0) == {"Mr. Bot went out!", "n1-0"}
      assert game.undo_seatno == 1
    end
  end

  describe "draw_discard" do
    test "removes the tile from discards and updates the player's exposed & turn state" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :drawing,
          discards: ["dp-0", "df-0", "dp-1"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.draw_discard(3, ["c1-0", "c1-1", "dp-0", "c2-0"], "dp-0")

      assert game.discards == ["df-0", "dp-1"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 3
      assert Enum.at(game.seats, 3).exposed == ["c1-0", "c1-1", "dp-0", "c2-0"]
      assert game.event_log |> Enum.at(0) == {"name3 drew the discarded tile.", "dp-0"}
      assert game.undo_seatno == 3
      assert game.undo_state.turn_seatno == 3
    end
  end

  describe "pong" do
    test "removes the tile from discards and updates the player's exposed, turn state, and turn" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :drawing,
          discards: ["dp-0", "df-0", "dp-1"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pong(0, ["c1-0", "c1-1", "dp-0", "c2-0"], "dp-0")

      assert game.discards == ["df-0", "dp-1"]
      assert game.turn_state == :discarding
      assert game.turn_seatno == 0
      assert Enum.at(game.seats, 0).exposed == ["c1-0", "c1-1", "dp-0", "c2-0"]
      assert game.event_log |> Enum.at(0) == {"name0 ponged.", "dp-0"}
      assert game.undo_seatno == 0
      assert game.undo_state.turn_seatno == 3
    end
  end

  describe "draw_correction_tile" do
    test "removes a tile from deck and updates the player's concealed tiles" do
      {game, returned_tile} =
        %Mjw.Game{
          turn_seatno: 3,
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
      assert Enum.at(game.seats, 0).concealed == ["c1-0", "c1-1", "dp-0", "c2-0"]
      assert returned_tile == "dp-0"
      assert game.event_log |> Enum.at(0) == {"name0 drew a correction tile.", nil}
      assert game.undo_seatno == 0
      assert game.undo_state.turn_seatno == 3
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
      assert game.event_log |> Enum.at(0) == {"name1 left the game.", nil}
    end
  end

  describe "boot" do
    test "removes a player from the given seatno" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.boot(1)

      assert Enum.map(game.seats, & &1.player_id) == ["id0", nil, "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", nil, "name2", "name3"]
      assert game.event_log |> Enum.at(0) == {"name1 was booted from the game.", "🥾"}
    end
  end

  describe "reset" do
    test "resets the game except for basic player info" do
      orig_game = %Mjw.Game{
        id: "6c1d42d8-28db-4b3b-a3f2-976d854e0394",
        dealer_seatno: 1,
        dealer_win_count: 1,
        turn_seatno: 3,
        turn_state: :discarding,
        deck: ["dp-1"],
        discards: ["dp-0"],
        dice: [1, 2, 3],
        wind: "wn",
        undo_seatno: 1,
        undo_state: %Mjw.Game{},
        event_log: [{"foo", "df-0"}],
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
              hiddengongs: ["n3-#{i}"],
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
      assert game.undo_state == nil
      assert game.undo_seatno == nil
      assert game.event_log == [{"The game was reset.", nil}]
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hiddengongs) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.wintile) == [nil, nil, nil, nil]
      assert Enum.map(game.seats, & &1.winreaction) == [nil, nil, nil, nil]
    end

    test "preserves bot players" do
      orig_game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()

      game = orig_game |> Mjw.Game.reset()

      assert Enum.map(game.seats, &Mjw.Seat.bot?(&1)) == [false, true, true, true]
      assert Enum.map(game.seats, & &1.player_name) == Enum.map(orig_game.seats, & &1.player_name)
      assert Enum.map(game.seats, &(&1.picked_wind == nil)) == [true, false, false, false]
      assert Enum.map(game.seats, &(&1.picked_wind_idx == nil)) == [true, false, false, false]
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
          turn_state: :discarding,
          wind: "wn",
          undo_seatno: 1,
          undo_state: %Mjw.Game{},
          event_log: [{"foo", "df-0"}],
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
                hiddengongs: ["n3-#{i}"],
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
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log == [{"The game was declared a draw.", "🤝"}]
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == ~w(ww we ws wn)
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hiddengongs) == [[], [], [], []]
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
          turn_state: :discarding,
          wind: "wn",
          undo_seatno: 1,
          undo_state: %Mjw.Game{},
          event_log: [{"foo", "df-0"}],
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
                hiddengongs: ["n3-#{i}"],
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
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log |> Enum.at(0) == {"name3 has been disqualified.", "🙅🏻‍♀️"}
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == ~w(ww we ws wn)
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hiddengongs) == [[], [], [], []]
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
          turn_state: :discarding,
          wind: "wn",
          undo_seatno: 1,
          undo_state: %Mjw.Game{},
          event_log: [{"foo", "df-0"}],
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
                hiddengongs: ["n3-#{i}"],
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
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log |> Enum.at(0) == {"name3 has been disqualified.", "🙅🏻‍♀️"}
      assert Enum.map(game.seats, & &1.player_id) == ["id0", "id1", "id2", "id3"]
      assert Enum.map(game.seats, & &1.player_name) == ["name0", "name1", "name2", "name3"]
      assert Enum.map(game.seats, & &1.picked_wind) == ~w(ww we ws wn)
      assert Enum.map(game.seats, & &1.concealed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.exposed) == [[], [], [], []]
      assert Enum.map(game.seats, & &1.hiddengongs) == [[], [], [], []]
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
          undo_seatno: 1,
          undo_state: %Mjw.Game{},
          event_log: [{"foo", "df-0"}],
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
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log == []
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
          undo_seatno: 1,
          undo_state: %Mjw.Game{},
          event_log: [{"foo", "df-0"}],
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
      assert game.undo_seatno == nil
      assert game.undo_state == nil
      assert game.event_log == []
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
    test "completely replaces the given seatno" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "Name0")
        |> Mjw.Game.seat_player("id1", "Name1")
        |> Mjw.Game.replace_seat(0, %Mjw.Seat{player_id: "id2", player_name: "Name2"})

      assert game.seats |> Enum.map(& &1.player_id) == ["id2", "id1", nil, nil]
      assert game.seats |> Enum.map(& &1.player_name) == ["Name2", "Name1", nil, nil]
    end
  end

  describe "undo" do
    test "undo a discard" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :discarding,
        discards: ["dp-0", "df-0"],
        deck: ["wn-1"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      {:ok, game} = Mjw.Game.discard(orig_game, 3, "n3-3")
      game = Mjw.Game.undo(game)

      expected_event_log = [{"name3 undid their action.", nil}, {"name3 discarded.", "n3-3"}]
      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "undo drawing a discard" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :drawing,
        discards: ["dp-0", "df-0"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      game =
        orig_game
        |> Mjw.Game.draw_discard(3, ["dp-0"], "dp-0")
        |> Mjw.Game.undo()

      expected_event_log = [
        {"name3 undid their action.", nil},
        {"name3 drew the discarded tile.", "dp-0"}
      ]

      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "undo pong" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :drawing,
        discards: ["dp-0", "df-0"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      game =
        orig_game
        |> Mjw.Game.pong(1, ["dp-0"], "dp-0")
        |> Mjw.Game.undo()

      expected_event_log = [
        {"name1 undid their action.", nil},
        {"name1 ponged.", "dp-0"}
      ]

      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "undo draw from deck" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :drawing,
        deck: ["b1-0", "b2-0", "b3-0"],
        discards: ["dp-0", "df-0"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      game =
        orig_game
        |> Mjw.Game.peek_deck_tile(3)
        |> Mjw.Game.clear_peektile(3)
        |> Mjw.Game.undo()

      expected_event_log = [
        {"name3 undid their action.", nil},
        {"name3 drew from the deck.", nil}
      ]

      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "undo draw correction tile" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :drawing,
        deck: ["b1-0", "b2-0", "b3-0"],
        discards: ["dp-0", "df-0"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      {game, "b1-0"} =
        orig_game |> Mjw.Game.draw_correction_tile(3, ["n1-3", "n2-3", "n3-3", "decktile"])

      game = game |> Mjw.Game.undo()

      expected_event_log = [
        {"name3 undid their action.", nil},
        {"name3 drew a correction tile.", nil}
      ]

      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "undo a declared win from discards" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :discarding,
        discards: ["dp-0", "df-0"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      game =
        orig_game
        |> Mjw.Game.declare_win_from_discards(1, "dp-0")
        |> Mjw.Game.undo()

      expected_event_log = [{"name1 undid their action.", nil}, {"name1 went out!", "dp-0"}]
      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "undo a declared win from player's hand" do
      orig_game = %Mjw.Game{
        turn_seatno: 3,
        turn_state: :discarding,
        discards: ["dp-0", "df-0"],
        seats:
          ~w(ww we ws wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{
              player_id: "id#{i}",
              player_name: "name#{i}",
              picked_wind: w,
              concealed: ["n1-#{i}", "n2-#{i}", "n3-#{i}"]
            }
          end)
      }

      game =
        orig_game
        |> Mjw.Game.declare_win_from_hand(1, "n3-1")
        |> Mjw.Game.undo()

      expected_event_log = [{"name1 undid their action.", nil}, {"name1 went out!", "n3-1"}]
      assert game == %{orig_game | event_log: expected_event_log}
    end

    test "bot seats are rolled back too" do
      orig_game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :discarding,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          seats
          |> List.update_at(0, fn seat ->
            %{seat | concealed: ["b5-0"]}
          end)
          |> List.update_at(1, fn seat ->
            %{
              seat
              | player_name: "bot1",
                concealed: ["b3-1", "b4-0", "c1-0"],
                exposed: ["b1-0", "b2-0", "b3-0", "n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> Map.merge(%{event_log: []})

      {:ok, game} = Mjw.Game.discard(orig_game, 0, "b5-0")

      game =
        game
        |> Mjw.Game.bot_draw()
        |> Mjw.Game.undo()

      expected_event_log = [
        {"name0 undid their action.", nil},
        {"bot1 drew the discarded tile.", "b5-0"},
        {"name0 discarded.", "b5-0"}
      ]

      assert game == %{orig_game | event_log: expected_event_log}
    end
  end

  describe "peek_deck_tile" do
    test "moves next tile from deck to player's hand" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :drawing,
          discards: ["dp-0", "df-0"],
          deck: ["c1-0", "c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.peek_deck_tile(3)

      assert game.deck == ["c2-0", "c3-0"]
      assert game.turn_seatno == 3
      assert game.turn_state == :discarding
      assert game.seats |> Enum.map(& &1.peektile) == [nil, nil, nil, "c1-0"]
      assert game.event_log |> Enum.at(0) == {"name3 drew from the deck.", nil}
      assert game.undo_seatno == 3
      assert game.undo_state.turn_seatno == 3
    end
  end

  describe "clear_peektile" do
    test "removes the peektile from the hand" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          seats: 0..3 |> Enum.map(fn i -> %Mjw.Seat{peektile: "b1-#{i}"} end)
        }
        |> Mjw.Game.clear_peektile(3)

      assert game.seats |> Enum.map(& &1.peektile) == ["b1-0", "b1-1", "b1-2", nil]
    end
  end

  describe "picked_east_wind_relative_seatno" do
    test "returns relative position of the player who picked east" do
      game = %Mjw.Game{
        seats:
          ~w(we ws ww wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_name: "name#{i}"}
          end)
      }

      assert game |> Mjw.Game.picked_east_wind_relative_seatno(0) == 0
      assert game |> Mjw.Game.picked_east_wind_relative_seatno(1) == 3
    end
  end

  describe "last_discarded_seatno" do
    test "returns nil if no discard was made" do
      game = %Mjw.Game{turn_state: :discarding}

      assert game |> Mjw.Game.last_discarded_seatno() == nil
    end

    test "returns the seatno of the player who just discarded" do
      {:ok, game} =
        %Mjw.Game{
          turn_state: :discarding,
          turn_seatno: 3,
          deck: ["dp-1"],
          seats:
            ~w(we ws ww wn)
            |> Enum.with_index()
            |> Enum.map(fn {w, i} ->
              %Mjw.Seat{picked_wind: w, player_name: "name#{i}"}
            end)
        }
        |> Mjw.Game.discard(3, "n1-1")

      assert game |> Mjw.Game.last_discarded_seatno() == 3
    end
  end

  describe "seat_bot" do
    test "does nothing if all seats are full" do
      game = %Mjw.Game{
        seats:
          ~w(we ws ww wn)
          |> Enum.with_index()
          |> Enum.map(fn {w, i} ->
            %Mjw.Seat{picked_wind: w, player_id: "id#{i}", player_name: "name#{i}"}
          end)
      }

      assert Mjw.Game.seat_bot(game) == game
    end

    test "adds a bot in the first empty seat" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()

      assert Mjw.Game.empty_seats_count(game) == 0
      bot_seat = game.seats |> Enum.at(3)
      assert Mjw.Seat.bot?(bot_seat)
      assert String.length(bot_seat.player_name) > 0
      {event, nil} = game.event_log |> Enum.at(0)
      assert event =~ ~r/.+ joined the game\.\z/
      assert bot_seat.picked_wind in ~w(we ws ww wn)
      assert bot_seat.picked_wind_idx in 0..3
    end
  end

  describe "bot_draw" do
    test "draws from deck" do
      game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["n1-0", "df-0"],
          deck: ["c1-0", "c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(0, fn seat -> %{seat | concealed: ["n1-0", "n2-0", "n3-0"]} end)
        end)
        |> Mjw.Game.bot_draw()

      assert game.deck == ["c2-0", "c3-0"]
      assert game.turn_seatno == 0
      assert game.turn_state == :discarding
      bot_seat = Enum.at(game.seats, 0)
      assert bot_seat.concealed == ["n1-0", "n2-0", "n3-0", "c1-0"]
      assert Enum.at(game.event_log, 0) == {"#{bot_seat.player_name} drew from the deck.", nil}
      assert game.undo_seatno == 3
    end

    test "draws from discards" do
      game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["n3-0", "df-0"],
          deck: ["c1-0", "c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats
          |> List.update_at(0, fn seat ->
            %{seat | concealed: ["n1-0", "n2-0", "b1-0", "b2-0"]}
          end)
        end)
        |> Mjw.Game.bot_draw()

      assert game.deck == ["c1-0", "c2-0", "c3-0"]
      assert game.turn_seatno == 0
      assert game.turn_state == :discarding
      assert game.undo_seatno == 3
      bot_seat = Enum.at(game.seats, 0)
      assert bot_seat.concealed == ["b1-0", "b2-0"]
      assert bot_seat.exposed == ["n1-0", "n3-0", "n2-0"]

      assert Enum.at(game.event_log, 0) ==
               {"#{bot_seat.player_name} drew the discarded tile.", "n3-0"}
    end

    test "zimo" do
      game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["n3-0", "df-0"],
          deck: ["c1-3", "c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> Mjw.Game.bot_draw()

      assert game.deck == ["c2-0", "c3-0"]
      assert game.turn_seatno == 0
      assert game.turn_state == :discarding
      assert game.undo_seatno == 3
      bot_seat = Enum.at(game.seats, 0)

      assert bot_seat.concealed == ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"]
      assert bot_seat.exposed == ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
      assert bot_seat.wintile == "c1-3"

      assert Enum.at(game.event_log, 0) ==
               {"#{bot_seat.player_name} picked themselves to win!", "c1-3"}
    end

    test "wins with discard" do
      game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> Mjw.Game.bot_draw()

      assert game.deck == ["c2-0", "c3-0"]
      assert game.turn_seatno == 0
      assert game.turn_state == :discarding
      assert game.undo_seatno == 3
      bot_seat = Enum.at(game.seats, 0)

      assert bot_seat.concealed == ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"]
      assert bot_seat.exposed == ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
      assert bot_seat.wintile == "c1-3"
      assert Enum.at(game.event_log, 0) == {"#{bot_seat.player_name} went out!", "c1-3"}
    end
  end

  describe "bots_try_win_out_of_turn" do
    test "no wins when no bots are out of turn" do
      result =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> Mjw.Game.bots_try_win_out_of_turn()

      assert result == :no_wins
    end

    test "no wins when bots are out of turn but cannot win" do
      result =
        %Mjw.Game{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["df-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> Mjw.Game.bots_try_win_out_of_turn()

      assert result == :no_wins
    end

    test "a bot wins out of turn" do
      {:ok, game} =
        %Mjw.Game{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> Mjw.Game.bots_try_win_out_of_turn()

      assert game.deck == ["c2-0", "c3-0"]
      assert game.turn_seatno == 0
      assert game.turn_state == :discarding
      assert game.undo_seatno == 3
      bot_seat = Enum.at(game.seats, 0)

      assert bot_seat.concealed == ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"]
      assert bot_seat.exposed == ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
      assert bot_seat.wintile == "c1-3"
      assert Enum.at(game.event_log, 0) == {"#{bot_seat.player_name} went out!", "c1-3"}
    end
  end

  describe "bots_present?" do
    test "returns true if any bots are present" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      assert Mjw.Game.bots_present?(game)
    end

    test "returns false if no bots are present" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      refute Mjw.Game.bots_present?(game)
    end

    test "returns false if no bots are present and game is partially filled" do
      game =
        %Mjw.Game{}
        |> Mjw.Game.seat_player("id0", "name0")

      refute Mjw.Game.bots_present?(game)
    end
  end
end
