defmodule Mjw.BotStrategyTest do
  use ExUnit.Case, async: true

  describe "draw" do
    test "chooses discard if it can win the game" do
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
            %{
              seat
              | concealed: [
                  "b1-0",
                  "b2-0",
                  "b3-1",
                  "b4-0",
                  "b5-0",
                  "b6-0",
                  "n1-0",
                  "n2-0",
                  "n9-0",
                  "n9-1"
                ],
                exposed: ["c7-0", "c8-0", "c9-1"]
            }
          end)
        end)

      assert Mjw.BotStrategy.draw(game) == :win_with_discard
    end

    test "chooses discard if it can win the game and concealed only has 1" do
      game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["n9-1", "df-0"],
          deck: ["c1-0", "c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats
          |> List.update_at(0, fn seat ->
            %{
              seat
              | concealed: ["n9-0"],
                exposed: [
                  "c7-0",
                  "c8-0",
                  "c9-1",
                  "b1-0",
                  "b2-0",
                  "b3-1",
                  "b4-0",
                  "b5-0",
                  "b6-0",
                  "n1-0",
                  "n2-0",
                  "n3-0"
                ]
            }
          end)
        end)

      assert Mjw.BotStrategy.draw(game) == :win_with_discard
    end

    test "chooses discard if it can complete a run" do
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
          List.update_at(seats, 0, fn seat ->
            %{seat | concealed: ["n1-0", "n2-0", "b1-0", "b2-0"]}
          end)
        end)

      assert Mjw.BotStrategy.draw(game) ==
               {:draw_discard, ["b1-0", "b2-0"], ["n1-0", "n3-0", "n2-0"]}
    end

    test "chooses deck tile if the discard is not desirable" do
      game =
        %Mjw.Game{
          turn_seatno: 0,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["n1-3", "df-0"],
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

      assert Mjw.BotStrategy.draw(game) == :zimo
    end

    test "wins with deck tile if the discard is not desirable and it completes a winning hand" do
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

      assert Mjw.BotStrategy.draw(game) == :draw_deck_tile
    end
  end

  describe "discard" do
    test "discards non-numeric tiles first" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-1", "n1-1", "c1-1", "c2-0", "c3-0", "c4-0", "wn-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "wn-0"
    end

    test "if all tiles are numeric, discards tiles that aren't contiguous with other tiles" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-1", "n1-1", "c1-1", "c2-0", "c3-0", "c4-0", "c5-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "n1-1"
    end

    test "if all tiles are numeric and contiguous, discards a tile with a sibling" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-1", "b2-2", "c1-1", "c2-0", "c3-0", "c4-0", "c4-1"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) in ["b2-1", "b2-2", "c4-0", "c4-1"]
    end

    test "if all tiles are numeric and contiguous and no siblings, discards rarest suit" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-1", "n1-2", "c1-1", "c2-0", "c3-0", "c4-0", "c5-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "n1-2"
    end

    test "concealed hand of 2 discards the rarest one in discards" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0", "n1-0", "n1-1", "n1-2"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["n1-3", "dp-1"],
                exposed: [
                  "n4-0",
                  "n2-0",
                  "n3-0",
                  "n4-0",
                  "n5-0",
                  "n6-0",
                  "c1-1",
                  "c2-0",
                  "c3-0",
                  "b4-2",
                  "b5-0",
                  "b6-0"
                ]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "n1-3"
    end

    test "concealed hand of runs + 2 discards the rarest one in discards" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0", "n1-0", "n1-1", "n1-2"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["b4-2", "b5-0", "b6-0", "n1-3", "dp-0"],
                exposed: [
                  "n4-0",
                  "n2-0",
                  "n3-0",
                  "n4-0",
                  "n5-0",
                  "n6-0",
                  "c1-1",
                  "c2-0",
                  "c3-0"
                ]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "n1-3"
    end

    test "concealed hand of 5 preserves a pair" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["n7-0", "n8-1", "b4-2", "b5-0", "b5-1"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0", "c1-1", "c2-0", "c3-0"]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "b4-2"
    end

    test "concealed hand of runs + 5 preserves a pair" do
      game =
        %Mjw.Game{
          turn_seatno: 3,
          turn_state: :discarding,
          discards: ["dp-0"],
          undo_seatno: 2
        }
        |> Mjw.Game.seat_player("id0", "name0")
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_bot()
        |> Map.update!(:seats, fn seats ->
          List.update_at(seats, 3, fn seat ->
            %{
              seat
              | concealed: ["b1-0", "b2-1", "b2-2", "c1-1", "c2-0", "c3-0", "c4-0", "c5-0"],
                exposed: ["n1-0", "n2-0", "n3-0", "n4-0", "n5-0", "n6-0"]
            }
          end)
        end)

      assert Mjw.BotStrategy.discard(game) == "b1-0"
    end
  end

  describe "find_win_out_of_turn" do
    test "finds no wins if no bots available out of turn" do
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
            %{
              seat
              | concealed: [
                  "b1-0",
                  "b2-0",
                  "b3-1",
                  "b4-0",
                  "b5-0",
                  "b6-0",
                  "n1-0",
                  "n2-0",
                  "n9-0",
                  "n9-1"
                ],
                exposed: ["c7-0", "c8-0", "c9-1"]
            }
          end)
        end)

      assert Mjw.BotStrategy.find_win_out_of_turn(game) == :no_wins
    end

    test "finds no wins of no bot can win" do
      game =
        %Mjw.Game{
          turn_seatno: 1,
          turn_state: :drawing,
          undo_seatno: 3,
          discards: ["df-0", "df-0"],
          deck: ["c1-0", "c2-0", "c3-0"]
        }
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_player("id1", "name1")
        |> Mjw.Game.seat_player("id2", "name2")
        |> Mjw.Game.seat_player("id3", "name3")
        |> Map.update!(:seats, fn seats ->
          seats
          |> List.update_at(0, fn seat ->
            %{
              seat
              | concealed: [
                  "b1-0",
                  "b2-0",
                  "b3-1",
                  "b4-0",
                  "b5-0",
                  "b6-0",
                  "n1-0",
                  "n2-0",
                  "n9-0",
                  "n9-1"
                ],
                exposed: ["c7-0", "c8-0", "c9-1"]
            }
          end)
        end)

      assert Mjw.BotStrategy.find_win_out_of_turn(game) == :no_wins
    end

    test "finds a win" do
      game =
        %Mjw.Game{
          turn_seatno: 1,
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
            %{
              seat
              | concealed: [
                  "b1-0",
                  "b2-0",
                  "b3-1",
                  "b4-0",
                  "b5-0",
                  "b6-0",
                  "n1-0",
                  "n2-0",
                  "n9-0",
                  "n9-1"
                ],
                exposed: ["c7-0", "c8-0", "c9-1"]
            }
          end)
        end)

      assert Mjw.BotStrategy.find_win_out_of_turn(game) == {:ok, 0}
    end
  end
end
