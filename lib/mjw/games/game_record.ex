defmodule Mjw.Games.GameRecord do
  @moduledoc """
  Ecto schema for persisting game state to the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field(:uuid, Ecto.UUID)
    field(:state, :map)

    timestamps(type: :utc_datetime)
  end

  def changeset(game_record, attrs) do
    game_record
    |> cast(attrs, [:uuid, :state])
    |> validate_required([:uuid, :state])
    |> unique_constraint(:uuid)
  end
end
