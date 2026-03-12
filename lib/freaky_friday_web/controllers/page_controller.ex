defmodule FreakyFridayWeb.PageController do
  alias FreakyFriday.Cache
  alias FreakyFriday.Room
  alias FreakyFriday.User
  use FreakyFridayWeb, :controller

  def home(conn, _params) do
    conn
    |> render(:home)
  end

  def join_guest(conn, %{"name" => name} = _params) do
    participant = FreakyFriday.Participant.new(name, FreakyFriday.gen_random_string())
    Room.join(participant)
    IO.inspect(Room.get_state(), label: "State after joining")

    conn
    |> put_session(:username, participant.name)
    |> put_session(:participant_id, participant.id)
    |> redirect(to: ~p"/freaky_friday")
  end

  def join_host(conn, _params) do
    user_id = get_session(conn, :user_id)

    # make sure user exists and has a refresh_token
    with {:ok, user} <- User.get_by_id(user_id),
         refresh_token when is_binary(refresh_token) <- user.refresh_token do
      participant = FreakyFriday.Participant.new(user.username, FreakyFriday.gen_random_string())
      Room.join(participant)
      Room.make_host(participant.id)
      Cache.set_refresh_token(refresh_token, user.expires_at)

      conn
      |> put_session(:username, participant.name)
      |> put_session(:participant_id, participant.id)
      |> put_session(:refresh_token, refresh_token)
      |> redirect(to: ~p"/freaky_friday")
    else
      _ ->
        conn
        |> redirect(to: ~p"/spotify_login")
    end
  end
end
