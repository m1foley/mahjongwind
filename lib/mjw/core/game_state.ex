defmodule Mjw.GameState do
  @doc """
  Calculate the state of a game
  """
  def state(%Mjw.Game{} = game) do
    {game, :tbd}
    |> waiting_for_players
    |> picking_winds
    |> rolling_for_first_dealer
    |> rolling_for_deal
    |> win_declared
    |> discarding
    |> drawing
    |> invalid
  end

  defp waiting_for_players({game, :tbd}) do
    if Mjw.Game.empty_seats_count(game) > 0 do
      {game, :waiting_for_players}
    else
      {game, :tbd}
    end
  end

  defp waiting_for_players({game, state}), do: {game, state}

  defp picking_winds({game, :tbd}) do
    if Enum.empty?(Mjw.Game.remaining_winds_to_pick(game)) do
      {game, :tbd}
    else
      {game, :picking_winds}
    end
  end

  defp picking_winds({game, state}), do: {game, state}

  defp rolling_for_first_dealer({game, :tbd}) do
    if Enum.empty?(game.dice) do
      {game, :rolling_for_first_dealer}
    else
      {game, :tbd}
    end
  end

  defp rolling_for_first_dealer({game, state}), do: {game, state}

  defp rolling_for_deal({game, :tbd}) do
    if game.turn_state == :rolling do
      {game, :rolling_for_deal}
    else
      {game, :tbd}
    end
  end

  defp rolling_for_deal({game, state}), do: {game, state}

  defp win_declared({game, :tbd}) do
    if Mjw.Game.win_declared_seatno(game) do
      {game, :win_declared}
    else
      {game, :tbd}
    end
  end

  defp win_declared({game, state}), do: {game, state}

  defp discarding({game, :tbd}) do
    if game.turn_state == :discarding do
      {game, :discarding}
    else
      {game, :tbd}
    end
  end

  defp discarding({game, state}), do: {game, state}

  defp drawing({game, :tbd}) do
    if game.turn_state == :drawing do
      {game, :drawing}
    else
      {game, :tbd}
    end
  end

  defp drawing({game, state}), do: {game, state}

  defp invalid({_game, :tbd}), do: :invalid
  defp invalid({_game, state}), do: state
end
