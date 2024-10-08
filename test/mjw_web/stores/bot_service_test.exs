defmodule MjwWeb.BotServiceTest do
  use ExUnit.Case, async: true
  doctest MjwWeb.BotService

  setup do
    MjwWeb.BotService.clear()
    {:ok, %{}}
  end

  describe "optionally_enqueue_roll" do
    test "enqueues rolling_for_first_dealer" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | picked_wind: "we"} end)
        end)
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)

      ^game = MjwWeb.BotService.optionally_enqueue_roll(game)
      assert MjwWeb.BotService.list() == [{:rolling_for_first_dealer, game.id, 1}]
    end

    test "enqueues rolling_for_deal" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :rolling, dealer_seatno: 1, dice: [1, 2, 3]})

      ^game = MjwWeb.BotService.optionally_enqueue_roll(game)
      assert MjwWeb.BotService.list() == [{:rolling_for_deal, game.id, 1}]
    end

    test "does nothing when the rolling player is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :rolling, dealer_seatno: 0, dice: [1, 2, 3]})

      ^game = MjwWeb.BotService.optionally_enqueue_draw(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the game is not in a rolling state" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")

      ^game = MjwWeb.BotService.optionally_enqueue_draw(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when bots are paused" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | picked_wind: "we"} end)
        end)
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.pause_bots()

      ^game = MjwWeb.BotService.optionally_enqueue_roll(game)
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "optionally_enqueue_draw" do
    test "enqueues a draw when it's a bot's turn to draw" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :drawing, turn_seatno: 1, dice: [1, 2, 3], discards: ["we-0"]})

      ^game = MjwWeb.BotService.optionally_enqueue_draw(game)
      assert MjwWeb.BotService.list() == [{:draw, game.id, 1}]
    end

    test "does nothing when the drawing player is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :drawing, turn_seatno: 0, dice: [1, 2, 3], discards: ["we-0"]})

      ^game = MjwWeb.BotService.optionally_enqueue_draw(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the game is not in a drawing state" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          dice: [1, 2, 3],
          discards: ["we-0"]
        })

      ^game = MjwWeb.BotService.optionally_enqueue_draw(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when bots are paused" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :drawing, turn_seatno: 1, dice: [1, 2, 3], discards: ["we-0"]})
        |> Mjw.Game.pause_bots()

      ^game = MjwWeb.BotService.optionally_enqueue_draw(game)
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "optionally_enqueue_try_win_out_of_turn" do
    test "enqueues when bots are out of turn" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :drawing, turn_seatno: 0, dice: [1, 2, 3], discards: ["we-0"]})

      ^game = MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn(game)
      assert MjwWeb.BotService.list() == [{:try_win_out_of_turn, game.id, 0}]
    end

    test "does nothing when no bots are out of turn" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :drawing, turn_seatno: 1, dice: [1, 2, 3], discards: ["we-0"]})

      ^game = MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the game is not in a drawing state" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 0,
          dice: [1, 2, 3],
          discards: ["we-0"]
        })

      ^game = MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when bots are paused" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :drawing, turn_seatno: 0, dice: [1, 2, 3], discards: ["we-0"]})
        |> Mjw.Game.pause_bots()

      ^game = MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn(game)
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "optionally_enqueue_discard" do
    test "enqueues a discard when it's a bot's turn to discard" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          dice: [1, 2, 3],
          discards: ["we-0"]
        })

      ^game = MjwWeb.BotService.optionally_enqueue_discard(game)
      assert MjwWeb.BotService.list() == [{:discard, game.id, 1}]
    end

    test "does nothing when the discarding player is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 0,
          dice: [1, 2, 3],
          discards: ["we-0"]
        })

      ^game = MjwWeb.BotService.optionally_enqueue_discard(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the game is not in a discarding state" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :drawing,
          turn_seatno: 1,
          dice: [1, 2, 3],
          discards: ["we-0"]
        })

      ^game = MjwWeb.BotService.optionally_enqueue_discard(game)
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when bots are paused" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          dice: [1, 2, 3],
          discards: ["we-0"]
        })
        |> Mjw.Game.pause_bots()

      ^game = MjwWeb.BotService.optionally_enqueue_discard(game)
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "perform_action rolling_for_first_dealer" do
    test "rolls, reseats players, and optionally enqueues another roll" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | picked_wind: "we"} end)
        end)
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_roll()

      :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
      send(MjwWeb.BotService, :perform_action)
      assert_receive {_game, :rolled_for_first_dealer, _event_details}
      :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)

      game = MjwWeb.GameStore.get(game.id)
      refute Enum.empty?(game.dice)
      assert Mjw.GameState.state(game) == :rolling_for_deal
    end

    test "does nothing when the state is not rolling_for_first_dealer" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | picked_wind: "we"} end)
        end)
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> MjwWeb.GameStore.persist()

      game
      |> Mjw.Game.pick_random_available_wind(3)
      |> MjwWeb.BotService.optionally_enqueue_roll()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the roller is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats
          |> List.update_at(1, fn seat -> %{seat | player_id: "not-a-bot", picked_wind: "we"} end)
        end)
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> MjwWeb.GameStore.persist()

      game
      |> Map.update!(:seats, fn seats ->
        seats
        |> List.update_at(1, fn seat -> %{seat | player_id: "bot"} end)
      end)
      |> MjwWeb.BotService.optionally_enqueue_roll()

      assert MjwWeb.BotService.list() != []
      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "perform_action rolling_for_deal" do
    test "rolls and deals" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :rolling, dealer_seatno: 1, dice: [1, 2, 3]})
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_roll()

      :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
      send(MjwWeb.BotService, :perform_action)
      assert_receive {_game, :rolled_for_deal, _event_details}
      :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)

      game = MjwWeb.GameStore.get(game.id)
      refute Enum.empty?(game.dice)
      assert Mjw.GameState.state(game) == :discarding
    end

    test "does nothing when the state is not rolling_for_deal" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :discarding, dealer_seatno: 1, dice: [1, 2, 3]})
        |> MjwWeb.GameStore.persist()

      game
      |> Map.merge(%{turn_state: :rolling})
      |> MjwWeb.BotService.optionally_enqueue_roll()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the roller is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{turn_state: :rolling, dealer_seatno: 2, dice: [1, 2, 3]})
        |> MjwWeb.GameStore.persist()

      game
      |> Map.merge(%{dealer_seatno: 1})
      |> MjwWeb.BotService.optionally_enqueue_roll()

      assert MjwWeb.BotService.list() != []
      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "perform_action draw" do
    test "draws and enqueues a discard" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :drawing,
          discards: ["we-0"],
          turn_seatno: 1,
          dice: [1, 2, 3],
          deck: ["b1-0", "b1-1", "b1-2"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_draw()

      :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
      send(MjwWeb.BotService, :perform_action)
      assert_receive {_game, :drew_from_deck, _event_details}
      :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)

      game = MjwWeb.GameStore.get(game.id)
      assert game.turn_seatno == 1
      assert Mjw.GameState.state(game) == :discarding
      bot_seat = Enum.at(game.seats, 1)
      assert bot_seat.concealed == ["n1-0", "n1-1", "b1-0"]
      assert game.deck == ["b1-1", "b1-2"]
      assert Enum.at(game.event_log, 0) == {"#{bot_seat.player_name} drew from the deck.", nil}
      assert MjwWeb.BotService.list() == [{:discard, game.id, 1}]
    end

    test "does nothing when the state is not drawing" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :drawing,
          discards: ["we-0"],
          turn_seatno: 1,
          dice: [1, 2, 3],
          deck: ["b1-0", "b1-1", "b1-2"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.GameStore.persist()

      %{game | turn_state: :discarding}
      |> MjwWeb.BotService.optionally_enqueue_draw()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the drawing player is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :drawing,
          discards: ["we-0"],
          turn_seatno: 1,
          dice: [1, 2, 3],
          deck: ["b1-0", "b1-1", "b1-2"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.GameStore.persist()

      %{game | turn_seatno: 2}
      |> MjwWeb.BotService.optionally_enqueue_draw()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when game is not persisted" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :drawing,
          discards: ["we-0"],
          turn_seatno: 1,
          dice: [1, 2, 3],
          deck: ["b1-0", "b1-1", "b1-2"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.BotService.optionally_enqueue_draw()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == nil
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "perform_action try_win_out_of_turn" do
    test "declares win" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"],
          dice: [1, 2, 3]
        })
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn()

      :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
      send(MjwWeb.BotService, :perform_action)
      assert_receive {_game, :declared_win, _event_details}
      :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)

      game = MjwWeb.GameStore.get(game.id)
      assert game.turn_seatno == 0
      assert Mjw.GameState.state(game) == :win_declared
      bot_seat = Enum.at(game.seats, 0)
      assert bot_seat.concealed == ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"]
      assert bot_seat.exposed == ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
      assert bot_seat.wintile == "c1-3"
      assert Enum.at(game.event_log, 0) == {"#{bot_seat.player_name} went out!", "c1-3"}
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the state is not drawing" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"],
          dice: [1, 2, 3]
        })
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> MjwWeb.GameStore.persist()

      %{game | turn_state: :discarding}
      |> MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when no bots are out of turn" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"],
          dice: [1, 2, 3]
        })
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> MjwWeb.GameStore.persist()

      %{game | turn_seatno: 0}
      |> MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when game is not persisted" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["c1-3", "n3-0", "df-0"],
          deck: ["c2-0", "c3-0"],
          dice: [1, 2, 3]
        })
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 0, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-0", "b2-1", "b3-0", "b3-1", "b4-0", "c1-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)
        |> MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == nil
      assert MjwWeb.BotService.list() == []
    end
  end

  describe "perform_action discard" do
    test "discards a concealed tile" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          discards: ["dp-0"],
          dice: [1, 2, 3]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["b1-0", "n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_discard()

      :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
      send(MjwWeb.BotService, :perform_action)
      assert_receive {_game, :discarded, _event_details}
      :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)

      game = MjwWeb.GameStore.get(game.id)
      assert game.turn_seatno == 2
      assert Mjw.GameState.state(game) == :drawing
      bot_seat = Enum.at(game.seats, 1)
      assert length(bot_seat.concealed) == 2
      {event_log_event, event_log_detail} = Enum.at(game.event_log, 0)
      assert event_log_event == "#{bot_seat.player_name} discarded."
      assert event_log_detail in ["b1-0", "n1-0", "n1-1"]
      assert length(game.discards) == 2
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when the discarding player is not a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          dice: [1, 2, 3],
          deck: ["b1-0", "b1-1", "b1-2"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_discard()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == game
      assert MjwWeb.BotService.list() == []
    end

    test "does nothing when game is not persisted" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          dice: [1, 2, 3],
          discards: ["dp-0"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["b1-0", "n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.BotService.optionally_enqueue_discard()

      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.GameStore.get(game.id) == nil
      assert MjwWeb.BotService.list() == []
    end

    test "enqueues another draw when the next player is a bot" do
      game =
        Mjw.Game.new()
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id3", "name3")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Map.merge(%{
          turn_state: :discarding,
          turn_seatno: 1,
          dice: [1, 2, 3],
          discards: ["dp-0"]
        })
        |> Map.update!(:seats, fn seats ->
          seats |> List.update_at(1, fn seat -> %{seat | concealed: ["b1-0", "n1-0", "n1-1"]} end)
        end)
        |> MjwWeb.GameStore.persist()
        |> MjwWeb.BotService.optionally_enqueue_discard()

      :ok = MjwWeb.GameStore.subscribe_to_game_updates(game)
      send(MjwWeb.BotService, :perform_action)
      assert_receive {_game, :discarded, _event_details}
      :ok = MjwWeb.GameStore.unsubscribe_from_game_updates(game)
      assert MjwWeb.BotService.list() == [{:draw, game.id, 2}]
    end
  end

  describe "perform_action when queue is empty" do
    test "does nothing (should never happen)" do
      send(MjwWeb.BotService, :perform_action)
      assert MjwWeb.BotService.list() == []
    end
  end
end
