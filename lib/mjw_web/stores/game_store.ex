defmodule MjwWeb.GameStore do
  @moduledoc """
  SQL-backed store for managing game state across the application.
  Uses PostgreSQL for persistence and Phoenix PubSub for real-time updates.
  The store handles game lifecycle operations including creation, updates,
  removal, and broadcasting changes to subscribed processes.
  """

  alias Mjw.Repo
  alias Mjw.Games.{GameRecord, GameSerializer}
  require Ecto.Query

  @doc """
  Create a new Game and persist it
  """
  def create do
    Mjw.Game.new()
    |> persist()
    |> broadcast_lobby_update(:game_created)
  end

  @doc """
  Persist an update to an existing game
  """
  def update(game, event, details \\ %{}) do
    game
    |> persist()
    |> broadcast_game_update(event, details)
  end

  @doc """
  Persist an update to an existing game that changes the game lobby
  """
  def update_with_lobby_change(game, event, details \\ %{}) do
    game
    |> update(event, details)
    |> broadcast_lobby_update(event)
  end

  @doc """
  Persist a game to the database (insert or update)
  """
  def persist(game) do
    state = GameSerializer.to_map(game)

    %GameRecord{id: game.id}
    |> GameRecord.changeset(%{id: game.id, state: state})
    |> Repo.insert!(
      on_conflict: {:replace, [:state, :updated_at]},
      conflict_target: :id
    )

    game
  end

  @doc """
  Remove a game from the database
  """

  def remove(game) do
    Repo.delete_all(Ecto.Query.from g in GameRecord, where: g.id == ^game.id)
    broadcast_lobby_update(game, :game_removed)
  end

  @doc """
  Get a game by ID
  """
  def get(game_id) do
    case Repo.get(GameRecord, game_id) do
      nil -> nil
      record -> GameSerializer.from_map(record.state)
    end
  end

  @doc """
  Get all games
  """
  def all do
    GameRecord
    |> Repo.all()
    |> Enum.map(&GameSerializer.from_map(&1.state))
  end

  @doc """
  Remove all stored games. Used in tests.
  """
  def clear do
    Repo.delete_all(GameRecord)
    :ok
  end

  @doc """
  Subscribe to lobby updates: a game is created, removed, or updates its seating
  """
  def subscribe_to_lobby_updates do
    Phoenix.PubSub.subscribe(Mjw.PubSub, "games")
  end

  def unsubscribe_from_lobby_updates do
    Phoenix.PubSub.unsubscribe(Mjw.PubSub, "games")
  end

  defp broadcast_lobby_update(game, event) do
    Phoenix.PubSub.broadcast(Mjw.PubSub, "games", {game, event})
    game
  end

  @doc """
  Subscribe to all updates for a particular game
  """
  def subscribe_to_game_updates(game) do
    Phoenix.PubSub.subscribe(Mjw.PubSub, "game:#{game.id}")
  end

  def unsubscribe_from_game_updates(game) do
    Phoenix.PubSub.unsubscribe(Mjw.PubSub, "game:#{game.id}")
  end

  defp broadcast_game_update(game, event, details) do
    Phoenix.PubSub.broadcast(Mjw.PubSub, "game:#{game.id}", {game, event, details})
    game
  end
end
