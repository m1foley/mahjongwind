defmodule Mjw.Games.GameRecord do
  @moduledoc """
  Ecto schema for persisting game state to the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "games" do
    field :state, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(game_record, attrs) do
    game_record
    |> cast(attrs, [:id, :state])
    |> validate_required([:id, :state])
  end
end
