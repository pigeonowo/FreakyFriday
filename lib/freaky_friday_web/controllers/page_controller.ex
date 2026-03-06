defmodule FreakyFridayWeb.PageController do
  use FreakyFridayWeb, :controller

  def home(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id == nil do
      conn
      |> redirect(to: ~p"/spotify_login")
    else
      access_token = FreakyFriday.get_user_access_token(user_id, conn)

      current_song =
        FreakyFriday.SpotifyApi.get_current_song!(access_token)
        |> dbg()

      conn
      |> assign(:current_song, current_song)
      |> render(:home)
    end
  end
end
