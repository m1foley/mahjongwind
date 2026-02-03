defmodule Mjw.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add(:uuid, :uuid, null: false)
      add(:state, :map, null: false)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:games, [:uuid])
  end
end
