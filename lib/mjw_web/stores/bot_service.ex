defmodule MjwWeb.BotService do
  use GenServer

  @default_action_delay :timer.seconds(11)
  @discard_action_delay :timer.seconds(7)

  # Client

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, initial(), name: __MODULE__)
  end

  def optionally_enqueue_roll(%Mjw.Game{} = game) do
    game_state = Mjw.Game.state(game)
    roller_seatno = Mjw.Game.current_roller_seatno(game, game_state)

    if roller_seatno && bot_sitting_at?(game, roller_seatno) do
      enqueue_delayed_action(game_state, game.id, roller_seatno)
    end

    game
  end

  def optionally_enqueue_draw(%Mjw.Game{} = game) do
    if bot_sitting_at?(game, game.turn_seatno) && Mjw.Game.state(game) == :drawing do
      enqueue_delayed_action(:draw, game.id, game.turn_seatno)
    end

    game
  end

  def optionally_enqueue_discard(%Mjw.Game{} = game) do
    if bot_sitting_at?(game, game.turn_seatno) && Mjw.Game.state(game) == :discarding do
      enqueue_discard(game)
    end

    game
  end

  def enqueue_discard(%Mjw.Game{turn_state: :discarding} = game) do
    enqueue_delayed_action(:discard, game.id, game.turn_seatno)
    game
  end

  def list(), do: GenServer.call(__MODULE__, :list)

  def clear(), do: GenServer.call(__MODULE__, :clear)

  # Callbacks

  @impl true
  def init(queue), do: {:ok, queue}

  @impl true
  def handle_cast({:enqueue_action, delay, action}, queue) do
    Process.send_after(self(), :perform_action, delay)
    new_queue = :queue.in(action, queue)
    {:noreply, new_queue}
  end

  @impl true
  def handle_info(:perform_action, queue) do
    case :queue.out(queue) do
      {{:value, {action_type, game_id, bot_seatno}}, remaining_queue} ->
        game = MjwWeb.GameStore.get(game_id)
        perform_action(action_type, game, bot_seatno)
        {:noreply, remaining_queue}

      {:empty, unexpected_empty_queue} ->
        {:noreply, unexpected_empty_queue}
    end
  end

  @impl true
  def handle_call(:list, _from, queue) do
    {:reply, :queue.to_list(queue), queue}
  end

  @impl true
  def handle_call(:clear, _from, _queue) do
    queue = initial()
    {:reply, queue, queue}
  end

  # Private methods

  defp initial(), do: :queue.new()

  defp enqueue_delayed_action(action_type, game_id, bot_seatno) do
    delay = action_delay(action_type)
    GenServer.cast(__MODULE__, {:enqueue_action, delay, {action_type, game_id, bot_seatno}})
  end

  defp action_delay(:discard), do: @discard_action_delay
  defp action_delay(_action_type), do: @default_action_delay

  defp perform_action(:rolling_for_first_dealer, %Mjw.Game{} = game, bot_seatno) do
    if Mjw.Game.state(game) == :rolling_for_first_dealer && bot_sitting_at?(game, bot_seatno) do
      game
      |> Mjw.Game.roll_dice()
      |> Mjw.Game.reseat_players()
      |> MjwWeb.GameStore.update(:rolled_for_first_dealer)
      |> optionally_enqueue_roll()
    end
  end

  defp perform_action(:rolling_for_deal, %Mjw.Game{} = game, bot_seatno) do
    if Mjw.Game.state(game) == :rolling_for_deal && bot_sitting_at?(game, bot_seatno) do
      game
      |> Mjw.Game.roll_dice()
      |> Mjw.Game.deal()
      |> MjwWeb.GameStore.update(:rolled_for_deal)
      |> optionally_enqueue_discard()
    end
  end

  # draw a deck tile into the bot's concealed tiles, and enqueue a discard
  defp perform_action(
         :draw,
         %Mjw.Game{turn_state: :drawing, turn_seatno: bot_seatno} = game,
         bot_seatno
       ) do
    if Mjw.Game.state(game) == :drawing && bot_sitting_at?(game, bot_seatno) do
      game
      |> Mjw.Game.bot_draw(bot_seatno)
      |> MjwWeb.GameStore.update(:drew_from_deck)
      |> enqueue_discard()
    end
  end

  defp perform_action(
         :discard,
         %Mjw.Game{turn_state: :discarding, turn_seatno: bot_seatno} = game,
         bot_seatno
       ) do
    if Mjw.Game.state(game) == :discarding && bot_sitting_at?(game, bot_seatno) do
      game
      |> Mjw.Game.bot_discard(bot_seatno)
      |> MjwWeb.GameStore.update(:discarded)
      |> optionally_enqueue_draw()
    end
  end

  defp perform_action(_action_type, _game, _bot_seatno), do: nil

  defp bot_sitting_at?(%Mjw.Game{seats: seats}, seatno) do
    Enum.at(seats, seatno) |> Mjw.Seat.bot?()
  end
end
