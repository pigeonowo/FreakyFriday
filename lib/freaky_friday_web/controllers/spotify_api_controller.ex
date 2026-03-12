defmodule FreakyFridayWeb.SpotifyApiController do
  use FreakyFridayWeb, :controller

  def callback(conn, %{"code" => code, "state" => _state} = _params) do
    {access_token, refresh_token, expires_at} = FreakyFriday.SpotifyApi.get_access_token!(code)

    profile = FreakyFriday.SpotifyApi.get_profile!(access_token)

    user =
      FreakyFriday.User.insert_or_update!(profile["display_name"], refresh_token, expires_at)

    # update access_token
    FreakyFriday.Cache.set_refresh_token(refresh_token, expires_at)

    conn
    |> put_session(:user_id, user.id)
    |> put_flash(:info, "Successfully logged into spotify as #{user.username}!")
    |> redirect(to: ~p"/")
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Login in to spotify went wrong...")
    |> redirect(to: ~p"/")
  end

  def login(conn, _params) do
    state = FreakyFriday.gen_random_string()
    IO.puts("State is: #{state}")

    conn
    |> put_session(:state, state)
    |> redirect(external: FreakyFriday.SpotifyApi.redirect_to_spotify_login(state))
  end
end
