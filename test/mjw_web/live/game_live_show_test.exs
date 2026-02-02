defmodule MjwWeb.GameLive.ShowTest do
  @moduledoc """
  Integration tests for the game show LiveView, covering the full game flow
  from joining to gameplay actions.
  """
  use MjwWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  setup do
    MjwWeb.GameStore.clear()
    :ok
  end

  describe "mount and joining a game" do
    test "redirects to home for nonexistent game", %{conn: conn} do
      fake_id = Ecto.UUID.generate()

      result = live(conn, ~p"/games/#{fake_id}")

      assert {:error,
              {:live_redirect, %{to: "/", flash: %{"error" => "That game ID does not exist."}}}} =
               result
    end

    test "shows seat offering modal for new player", %{conn: conn} do
      game = MjwWeb.GameStore.create()

      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Have a seat!"
      assert html =~ "Your name:"
      assert html =~ "Sit"
    end

    test "allows player to join by entering name", %{conn: conn} do
      game = MjwWeb.GameStore.create()

      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      html =
        view
        |> form("#seat-offering-form", player_name: "Alice")
        |> render_submit()

      refute html =~ "Have a seat!"
      assert html =~ "Waiting for"
      assert html =~ "more players"
    end

    test "prevents joining a full game", %{conn: conn} do
      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player("p1", "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> MjwWeb.GameStore.update(:players_seated)

      result = live(conn, ~p"/games/#{game.id}")

      assert {:error,
              {:live_redirect, %{to: "/", flash: %{"error" => "Sorry, that game is full."}}}} =
               result
    end

    test "existing player can rejoin the game", %{conn: conn} do
      # Create a user_id that we'll use for both seating and the session
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> MjwWeb.GameStore.update(:players_seated)

      # Connect with the same user_id
      conn = assign_user_session(conn, user_id)
      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      # Should not show seat offering since player is already seated
      refute html =~ "Have a seat!"
    end
  end

  describe "waiting for players state" do
    test "shows correct player count", %{conn: conn} do
      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player("p1", "Alice")
        |> MjwWeb.GameStore.update(:player_joined)

      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      view
      |> form("#seat-offering-form", player_name: "Bob")
      |> render_submit()

      updated_game = MjwWeb.GameStore.get(game.id)
      assert length(Mjw.Game.seated_player_names(updated_game)) == 2
    end

    test "shows add bot button", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> MjwWeb.GameStore.update(:player_joined)

      conn = assign_user_session(conn, user_id)
      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Add bot"
    end

    test "can add bot player", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> MjwWeb.GameStore.update(:player_joined)

      conn = assign_user_session(conn, user_id)
      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      view |> element("#invite-link-center-addbot") |> render_click()

      updated_game = MjwWeb.GameStore.get(game.id)
      assert Mjw.Game.bots_present?(updated_game)
    end
  end

  describe "picking winds state" do
    test "shows wind picking interface", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> MjwWeb.GameStore.update(:players_seated)

      conn = assign_user_session(conn, user_id)
      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      # Wind picking tiles should be visible
      assert html =~ "Pick a wind"
    end

    test "allows player to pick wind", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> MjwWeb.GameStore.update(:players_seated)

      conn = assign_user_session(conn, user_id)
      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      view |> element(".pickable-wind[phx-value-picked-wind-idx='0']") |> render_click()

      updated_game = MjwWeb.GameStore.get(game.id)
      assert Mjw.Game.picked_wind(updated_game, user_id) != nil
    end
  end

  describe "rolling for first dealer state" do
    test "shows dice roll interface for east wind picker", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      # Create game where user_id picks East wind
      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> then(fn game ->
          # Force the first player to have East wind
          game
          |> Map.update!(:seats, fn seats ->
            List.update_at(seats, 0, fn seat ->
              %{seat | picked_wind: "we", picked_wind_idx: 0}
            end)
          end)
        end)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> MjwWeb.GameStore.update(:winds_picked)

      conn = assign_user_session(conn, user_id)
      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Roll to determine first dealer"
    end

    test "rolling dice advances game state", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> then(fn game ->
          game
          |> Map.update!(:seats, fn seats ->
            List.update_at(seats, 0, fn seat ->
              %{seat | picked_wind: "we", picked_wind_idx: 0}
            end)
          end)
        end)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> MjwWeb.GameStore.update(:winds_picked)

      conn = assign_user_session(conn, user_id)
      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      view |> element(".hand") |> render_click()

      updated_game = MjwWeb.GameStore.get(game.id)
      assert Mjw.GameState.state(updated_game) == :rolling_for_deal
    end
  end

  describe "game in play" do
    test "shows player's tiles when it's their turn to discard", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()
        |> MjwWeb.GameStore.update(:dealt)

      # Find the player whose turn it is (dealer)
      dealer = Enum.at(game.seats, game.turn_seatno)
      conn = assign_user_session(conn, dealer.player_id)

      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      # Players should see their concealed tiles - check for the tile container
      assert html =~ "concealed-0"
    end

    test "shows discards area", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()
        |> MjwWeb.GameStore.update(:dealt)

      dealer = Enum.at(game.seats, game.turn_seatno)
      conn = assign_user_session(conn, dealer.player_id)

      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "discards"
    end

    test "shows deck remaining count", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()
        |> MjwWeb.GameStore.update(:dealt)

      dealer = Enum.at(game.seats, game.turn_seatno)
      conn = assign_user_session(conn, dealer.player_id)

      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "deck-remaining-count"
    end
  end

  describe "game menu" do
    test "can open game menu", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()
        |> MjwWeb.GameStore.update(:dealt)

      dealer = Enum.at(game.seats, game.turn_seatno)
      conn = assign_user_session(conn, dealer.player_id)

      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      html = view |> element(".gamewind") |> render_click()

      assert html =~ "Leave game"
    end
  end

  describe "undo functionality" do
    test "undo button not visible before first discard", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_player("p2", "Bob")
        |> Mjw.Game.seat_player("p3", "Carol")
        |> Mjw.Game.seat_player("p4", "Dave")
        |> Mjw.Game.pick_random_available_wind(0)
        |> Mjw.Game.pick_random_available_wind(1)
        |> Mjw.Game.pick_random_available_wind(2)
        |> Mjw.Game.pick_random_available_wind(3)
        |> Mjw.Game.roll_dice_and_reseat_players()
        |> Mjw.Game.roll_dice_and_deal()
        |> MjwWeb.GameStore.update(:dealt)

      dealer = Enum.at(game.seats, game.turn_seatno)
      conn = assign_user_session(conn, dealer.player_id)

      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      refute html =~ ~r/<div[^>]*id="undo"/
    end
  end

  describe "bot actions" do
    test "shows pause bots button when bots present and winds picked", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.pick_random_available_wind(0)
        |> MjwWeb.GameStore.update(:bots_seated)

      conn = assign_user_session(conn, user_id)
      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Pause bots"
    end

    test "can pause bots", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.seat_bot()
        |> Mjw.Game.pick_random_available_wind(0)
        |> MjwWeb.GameStore.update(:bots_seated)

      conn = assign_user_session(conn, user_id)
      {:ok, view, _html} = live(conn, ~p"/games/#{game.id}")

      html = view |> element("#pausebots") |> render_click()

      assert html =~ "Resume bots"
      updated_game = MjwWeb.GameStore.get(game.id)
      assert updated_game.pause_bots == true
    end
  end

  describe "invite link" do
    test "shows invite link when waiting for players", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      game =
        MjwWeb.GameStore.create()
        |> Mjw.Game.seat_player(user_id, "Alice")
        |> MjwWeb.GameStore.update(:player_joined)

      conn = assign_user_session(conn, user_id)
      {:ok, _view, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "invite-link"
      assert html =~ game.id
    end
  end

  # Helper to set user_id in the session
  defp assign_user_session(conn, user_id) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> put_session(:user_id, user_id)
  end
end
