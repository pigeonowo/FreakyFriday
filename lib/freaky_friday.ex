defmodule FreakyFriday do
  @moduledoc """
  FreakyFriday keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_user_access_token(user_id, %Plug.Conn{} = conn) do
    user = FreakyFriday.User.get_by_id!(user_id)

    access_token =
      if FreakyFriday.SpotifyApi.token_needs_refresh?(user.expires_at) do
        {a_tok, r_tok, e_at} = FreakyFriday.SpotifyApi.refresh_token(user.refresh_token)

        if r_tok do
          changeset =
            FreakyFriday.User.changeset(user, %{refresh_token: r_tok, expires_at: e_at})

          _ = FreakyFriday.Repo.update!(changeset)
        end

        a_tok
      else
        Plug.Conn.get_session(conn, :access_token)
      end

    access_token
  end

  def update_token(user) do
    {access_token, refresh_token, expires_at} =
      FreakyFriday.SpotifyApi.refresh_token(user.refresh_token)

    if refresh_token do
      cs =
        FreakyFriday.User.changeset(user, %{refresh_token: refresh_token, expires_at: expires_at})

      FreakyFriday.Repo.update!(cs)
    end

    access_token
  end
end
