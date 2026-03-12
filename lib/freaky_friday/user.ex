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
    |> validate_required([:username])
  end

  def insert_or_update!(username, refresh_token, expires_at) do
    case Repo.get_by(__MODULE__, username: username) do
      %__MODULE__{} = user ->
        cs = changeset(user, %{refresh_token: refresh_token, expires_at: expires_at})
        FreakyFriday.Repo.update!(cs)

      nil ->
        cs =
          FreakyFriday.User.changeset(%FreakyFriday.User{}, %{
            username: username,
            refresh_token: refresh_token,
            expires_at: expires_at
          })

        FreakyFriday.Repo.insert!(cs)
    end
  end

  def get_by_id!(id) do
    case id do
      nil -> nil
      _ -> Repo.get_by!(__MODULE__, id: id)
    end
  end

  def get_by_id(id) do
    case id do
      nil ->
        {:error, "id is nil"}

      _ ->
        case Repo.get_by(__MODULE__, id: id) do
          nil -> {:error, "not found"}
          user -> {:ok, user}
        end
    end
  end

  def update_refreshtoken(user) do
    {_access_token, refresh_token, expires_at} =
      FreakyFriday.SpotifyApi.refresh_token(user.refresh_token)

    if refresh_token do
      cs =
        FreakyFriday.User.changeset(user, %{refresh_token: refresh_token, expires_at: expires_at})

      FreakyFriday.Repo.update!(cs)
    end

    nil
  end
end
