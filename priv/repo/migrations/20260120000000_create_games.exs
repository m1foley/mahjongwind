defmodule Mjw.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:state, :map, null: false)

      timestamps(type: :utc_datetime)
    end
  end
end
