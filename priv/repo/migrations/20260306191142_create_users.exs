defmodule FreakyFriday.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :refresh_token, :string
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
