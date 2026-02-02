defmodule Mjw.Games.GameSerializerTest do
  use ExUnit.Case, async: true
  alias Mjw.Games.GameSerializer

  describe "to_map/1" do
    test "converts a basic Game struct to a map" do
      game = Mjw.Game.new("test-id-123")

      result = GameSerializer.to_map(game)

      assert is_map(result)
      assert result.id == "test-id-123"
      assert result.wind == "we"
      assert result.discards == []
      assert result.turn_state == :rolling
      assert result.dealer_seatno == 0
      assert result.turn_seatno == 0
      assert result.dealer_win_count == 0
      assert result.event_log == []
      assert result.undo_seatno == nil
      assert result.undo_state == nil
      assert result.pause_bots == false
      assert length(result.deck) == 136
      assert length(result.seats) == 4
    end

    test "converts seats to maps" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("player-1", "Alice")
        |> Mjw.Game.seat_player("player-2", "Bob")

      result = GameSerializer.to_map(game)

      [seat1, seat2, seat3, seat4] = result.seats
      assert is_map(seat1)
      assert seat1.player_id == "player-1"
      assert seat1.player_name == "Alice"
      assert seat2.player_id == "player-2"
      assert seat2.player_name == "Bob"
      assert seat3.player_id == nil
      assert seat4.player_id == nil
    end

    test "converts event_log tuples to lists" do
      game = %Mjw.Game{
        event_log: [{"Player went out!", "n1-0"}, {"Player discarded.", "b2-1"}]
      }

      result = GameSerializer.to_map(game)

      assert result.event_log == [["Player went out!", "n1-0"], ["Player discarded.", "b2-1"]]
    end

    test "handles nil undo_state" do
      game = %Mjw.Game{undo_state: nil}

      result = GameSerializer.to_map(game)

      assert result.undo_state == nil
    end

    test "recursively converts undo_state Game struct" do
      inner_game = %Mjw.Game{
        id: "inner-id",
        wind: "ws",
        turn_state: :drawing,
        event_log: [{"Inner event", nil}]
      }

      game = %Mjw.Game{
        id: "outer-id",
        undo_state: inner_game
      }

      result = GameSerializer.to_map(game)

      assert is_map(result.undo_state)
      assert result.undo_state.id == "inner-id"
      assert result.undo_state.wind == "ws"
      assert result.undo_state.turn_state == :drawing
      assert result.undo_state.event_log == [["Inner event", nil]]
    end

    test "converts seat winreaction atoms" do
      game = %Mjw.Game{
        seats: [
          %Mjw.Seat{winreaction: :ok},
          %Mjw.Seat{winreaction: :expose},
          %Mjw.Seat{winreaction: :expose_ok},
          %Mjw.Seat{winreaction: nil}
        ]
      }

      result = GameSerializer.to_map(game)

      assert Enum.at(result.seats, 0).winreaction == :ok
      assert Enum.at(result.seats, 1).winreaction == :expose
      assert Enum.at(result.seats, 2).winreaction == :expose_ok
      assert Enum.at(result.seats, 3).winreaction == nil
    end
  end

  describe "from_map/1" do
    test "returns nil for nil input" do
      assert GameSerializer.from_map(nil) == nil
    end

    test "converts a map with string keys to a Game struct" do
      map = %{
        "id" => "test-id-456",
        "deck" => ["b1-0", "b2-0"],
        "discards" => ["n1-0"],
        "wind" => "ws",
        "dice" => [1, 2, 3],
        "turn_state" => "drawing",
        "dealer_seatno" => 1,
        "turn_seatno" => 2,
        "dealpick_seatno" => 0,
        "dealer_win_count" => 1,
        "event_log" => [["Event 1", "n1-0"]],
        "undo_seatno" => 1,
        "undo_state" => nil,
        "pause_bots" => true,
        "seats" => [
          %{"player_id" => "p1", "player_name" => "Alice", "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => "we",
            "picked_wind_idx" => 0, "winreaction" => nil, "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
        ]
      }

      result = GameSerializer.from_map(map)

      assert %Mjw.Game{} = result
      assert result.id == "test-id-456"
      assert result.deck == ["b1-0", "b2-0"]
      assert result.discards == ["n1-0"]
      assert result.wind == "ws"
      assert result.dice == [1, 2, 3]
      assert result.turn_state == :drawing
      assert result.dealer_seatno == 1
      assert result.turn_seatno == 2
      assert result.dealer_win_count == 1
      assert result.event_log == [{"Event 1", "n1-0"}]
      assert result.undo_seatno == 1
      assert result.pause_bots == true
    end

    test "converts a map with atom keys to a Game struct" do
      map = %{
        id: "test-id-789",
        deck: ["c1-0"],
        discards: [],
        wind: "we",
        dice: [],
        turn_state: :rolling,
        dealer_seatno: 0,
        turn_seatno: 0,
        dealpick_seatno: 0,
        dealer_win_count: 0,
        event_log: [],
        undo_seatno: nil,
        undo_state: nil,
        pause_bots: false,
        seats: [
          %{player_id: nil, player_name: nil, concealed: [], exposed: [],
            hiddengongs: [], peektile: nil, wintile: nil, picked_wind: nil,
            picked_wind_idx: nil, winreaction: nil, seatno: nil, win_expose: nil},
          %{player_id: nil, player_name: nil, concealed: [], exposed: [],
            hiddengongs: [], peektile: nil, wintile: nil, picked_wind: nil,
            picked_wind_idx: nil, winreaction: nil, seatno: nil, win_expose: nil},
          %{player_id: nil, player_name: nil, concealed: [], exposed: [],
            hiddengongs: [], peektile: nil, wintile: nil, picked_wind: nil,
            picked_wind_idx: nil, winreaction: nil, seatno: nil, win_expose: nil},
          %{player_id: nil, player_name: nil, concealed: [], exposed: [],
            hiddengongs: [], peektile: nil, wintile: nil, picked_wind: nil,
            picked_wind_idx: nil, winreaction: nil, seatno: nil, win_expose: nil}
        ]
      }

      result = GameSerializer.from_map(map)

      assert %Mjw.Game{} = result
      assert result.id == "test-id-789"
      assert result.turn_state == :rolling
    end

    test "converts event_log lists to tuples" do
      map = %{
        "id" => "test",
        "deck" => [],
        "discards" => [],
        "wind" => "we",
        "dice" => [],
        "turn_state" => "rolling",
        "dealer_seatno" => 0,
        "turn_seatno" => 0,
        "dealpick_seatno" => 0,
        "dealer_win_count" => 0,
        "event_log" => [["First event", "tile-1"], ["Second event", nil]],
        "undo_seatno" => nil,
        "undo_state" => nil,
        "pause_bots" => false,
        "seats" => Enum.map(1..4, fn _ ->
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
        end)
      }

      result = GameSerializer.from_map(map)

      assert result.event_log == [{"First event", "tile-1"}, {"Second event", nil}]
    end

    test "converts turn_state string to atom" do
      for turn_state <- ["rolling", "drawing", "discarding"] do
        map = %{
          "id" => "test",
          "deck" => [],
          "discards" => [],
          "wind" => "we",
          "dice" => [],
          "turn_state" => turn_state,
          "dealer_seatno" => 0,
          "turn_seatno" => 0,
          "dealpick_seatno" => 0,
          "dealer_win_count" => 0,
          "event_log" => [],
          "undo_seatno" => nil,
          "undo_state" => nil,
          "pause_bots" => false,
          "seats" => Enum.map(1..4, fn _ ->
            %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
              "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
              "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
          end)
        }

        result = GameSerializer.from_map(map)

        assert result.turn_state == String.to_atom(turn_state)
      end
    end

    test "converts seats with winreaction strings to atoms" do
      map = %{
        "id" => "test",
        "deck" => [],
        "discards" => [],
        "wind" => "we",
        "dice" => [],
        "turn_state" => "rolling",
        "dealer_seatno" => 0,
        "turn_seatno" => 0,
        "dealpick_seatno" => 0,
        "dealer_win_count" => 0,
        "event_log" => [],
        "undo_seatno" => nil,
        "undo_state" => nil,
        "pause_bots" => false,
        "seats" => [
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => "ok", "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => "expose", "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => "expose_ok", "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
        ]
      }

      result = GameSerializer.from_map(map)

      assert Enum.at(result.seats, 0).winreaction == :ok
      assert Enum.at(result.seats, 1).winreaction == :expose
      assert Enum.at(result.seats, 2).winreaction == :expose_ok
      assert Enum.at(result.seats, 3).winreaction == nil
    end

    test "recursively converts undo_state map" do
      map = %{
        "id" => "outer",
        "deck" => [],
        "discards" => [],
        "wind" => "we",
        "dice" => [],
        "turn_state" => "rolling",
        "dealer_seatno" => 0,
        "turn_seatno" => 0,
        "dealpick_seatno" => 0,
        "dealer_win_count" => 0,
        "event_log" => [],
        "undo_seatno" => 1,
        "pause_bots" => false,
        "undo_state" => %{
          "id" => "inner",
          "deck" => ["b1-0"],
          "discards" => ["n1-0"],
          "wind" => "ws",
          "dice" => [1, 2, 3],
          "turn_state" => "drawing",
          "dealer_seatno" => 1,
          "turn_seatno" => 2,
          "dealpick_seatno" => 0,
          "dealer_win_count" => 1,
          "event_log" => [["Inner event", nil]],
          "undo_seatno" => nil,
          "undo_state" => nil,
          "pause_bots" => false,
          "seats" => Enum.map(1..4, fn _ ->
            %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
              "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
              "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
          end)
        },
        "seats" => Enum.map(1..4, fn _ ->
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
        end)
      }

      result = GameSerializer.from_map(map)

      assert %Mjw.Game{} = result.undo_state
      assert result.undo_state.id == "inner"
      assert result.undo_state.deck == ["b1-0"]
      assert result.undo_state.wind == "ws"
      assert result.undo_state.turn_state == :drawing
      assert result.undo_state.event_log == [{"Inner event", nil}]
    end

    test "raises on invalid turn_state value" do
      map = %{
        "id" => "test",
        "deck" => [],
        "discards" => [],
        "wind" => "we",
        "dice" => [],
        "turn_state" => "invalid_state",
        "dealer_seatno" => 0,
        "turn_seatno" => 0,
        "dealpick_seatno" => 0,
        "dealer_win_count" => 0,
        "event_log" => [],
        "undo_seatno" => nil,
        "undo_state" => nil,
        "pause_bots" => false,
        "seats" => Enum.map(1..4, fn _ ->
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
        end)
      }

      assert_raise ArgumentError, ~r/Invalid atom value/, fn ->
        GameSerializer.from_map(map)
      end
    end

    test "raises on invalid winreaction value" do
      map = %{
        "id" => "test",
        "deck" => [],
        "discards" => [],
        "wind" => "we",
        "dice" => [],
        "turn_state" => "rolling",
        "dealer_seatno" => 0,
        "turn_seatno" => 0,
        "dealpick_seatno" => 0,
        "dealer_win_count" => 0,
        "event_log" => [],
        "undo_seatno" => nil,
        "undo_state" => nil,
        "pause_bots" => false,
        "seats" => [
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => "invalid_reaction", "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil},
          %{"player_id" => nil, "player_name" => nil, "concealed" => [], "exposed" => [],
            "hiddengongs" => [], "peektile" => nil, "wintile" => nil, "picked_wind" => nil,
            "picked_wind_idx" => nil, "winreaction" => nil, "seatno" => nil, "win_expose" => nil}
        ]
      }

      assert_raise ArgumentError, ~r/Invalid atom value/, fn ->
        GameSerializer.from_map(map)
      end
    end
  end

  describe "roundtrip serialization" do
    test "to_map and from_map are inverse operations for a basic game" do
      original = Mjw.Game.new("roundtrip-test")

      result =
        original
        |> GameSerializer.to_map()
        |> GameSerializer.from_map()

      assert result == original
    end

    test "to_map and from_map preserve a game with players" do
      original =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("p1", "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)

      result =
        original
        |> GameSerializer.to_map()
        |> GameSerializer.from_map()

      assert result == original
    end

    test "to_map and from_map preserve a game in play" do
      original =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("p1", "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()

      result =
        original
        |> GameSerializer.to_map()
        |> GameSerializer.from_map()

      assert result == original
    end

    test "to_map and from_map preserve a game with undo state" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("p1", "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()

      # Find a tile in the dealer's hand to discard
      dealer_seatno = game.turn_seatno
      tile_to_discard = game.seats |> Enum.at(dealer_seatno) |> Map.get(:concealed) |> hd()

      {:ok, original} = Mjw.Game.discard(game, dealer_seatno, tile_to_discard)

      # The original should have an undo_state
      assert original.undo_state != nil

      result =
        original
        |> GameSerializer.to_map()
        |> GameSerializer.from_map()

      assert result == original
    end

    test "to_map and from_map preserve a game with win declared" do
      game =
        %Mjw.Game{
          turn_seatno: 1,
          turn_state: :discarding,
          seats: [
            %Mjw.Seat{player_id: "p1", player_name: "Alice", winreaction: :ok},
            %Mjw.Seat{player_id: "p2", player_name: "Bob", wintile: "n1-0", winreaction: :expose},
            %Mjw.Seat{player_id: "p3", player_name: "Carol", winreaction: :expose_ok},
            %Mjw.Seat{player_id: "p4", player_name: "Dave", winreaction: nil}
          ]
        }

      result =
        game
        |> GameSerializer.to_map()
        |> GameSerializer.from_map()

      assert result == game
    end
  end
end
