defmodule FreakyFriday.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias FreakyFriday.Repo

  schema "users" do
    field :username, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :refresh_token, :expires_at])
    |> validate_required([:username, :refresh_token, :expires_at])
  end

  def insert!(username, refresh_token, expires_at) do
    changeset =
      FreakyFriday.User.changeset(%FreakyFriday.User{}, %{
        username: username,
        refresh_token: refresh_token,
        expires_at: expires_at
      })

    FreakyFriday.Repo.insert!(changeset)
  end

  def get_by_id!(id) do
    Repo.get_by!(__MODULE__, id: id)
  end
end
