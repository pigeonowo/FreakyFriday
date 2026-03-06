defmodule FreakyFriday.SpotifyApi do
  @moduledoc """
  Functions for interacting with the Spotify API.
  It is also responsible for AUTH.
  """

  @spotify_api_url "https://api.spotify.com/v1"
  @auth_url "https://accounts.spotify.com/authorize"
  @token_url "https://accounts.spotify.com/api/token"
  @redirect_uri "http://127.0.0.1:4000/spotify_callback"
  @scope "user-read-private user-read-email"

  @doc """
  Gets the auth url with the params.
  """

  def get_profile(access_token) do
    Req.get!(@spotify_api_url <> "/me", headers: %{Authorization: "Bearer #{access_token}"})
  end

  # AUTH STUFF
  @spec redirect_to_spotify_login(state :: String.t()) :: String.t()
  def redirect_to_spotify_login(state) do
    params = %{
      "response_type" => "code",
      "client_id" => get_client_id(),
      "scope" => @scope,
      "redirect_uri" => @redirect_uri,
      "state" => state
    }

    URI.new!(@auth_url)
    |> URI.append_query(URI.encode_query(params))
    |> URI.to_string()
  end

  @spec token_needs_refresh?(DateTime.t()) :: boolean()
  def token_needs_refresh?(%DateTime{} = expires_at) do
    case DateTime.now!("Etc/UTC") |> DateTime.compare(expires_at) do
      :lt -> false
      :gt -> true
      :eq -> true
    end
  end

  @spec get_access_token!(authorization_code :: String.t()) ::
          {token :: String.t(), refresh_token :: String.t(), expires_at :: DateTime.t()}
  def get_access_token!(authorization_code) do
    id = get_client_id()
    secret = get_client_secret()

    res =
      Req.post!(@token_url,
        headers: [
          {"Content-Type", "application/x-www-form-urlencoded"},
          {"Authorization", "Basic #{Base.encode64(id <> ":" <> secret)}"}
        ],
        body:
          "code=#{authorization_code}&redirect_uri=#{@redirect_uri}&grant_type=authorization_code"
      )
      |> dbg()

    expires_at =
      DateTime.now!("Etc/UTC")
      |> DateTime.add(res.body["expires_in"], :second)

    {res.body["access_token"], res.body["refresh_token"], expires_at}
  end

  @doc """
  Refresh token might be nil. Keep using the old one if so.
  """
  @spec refresh_token(refresh_token :: String.t()) :: {String.t(), String.t() | nil, DateTime.t()}
  def refresh_token(refresh_token) do
    id = get_client_id()
    secret = get_client_secret()

    res =
      Req.post!(@token_url,
        headers: [
          {"Content-Type", "application/x-www-form-urlencoded"},
          {"Authorization", "Basic #{Base.encode64(id <> ":" <> secret)}"}
        ],
        body: "refresh_token=#{refresh_token}&grant_type=refresh_token"
      )
      |> dbg()

    expires_at =
      DateTime.now!("Etc/UTC")
      |> DateTime.add(res.body["expires_in"], :second)

    {res.body["access_token"], res.body["refresh_token"], expires_at}
  end

  @spec get_client_id() :: String.t()
  def get_client_secret() do
    Application.fetch_env!(:freaky_friday, :spotify_api_client_secret)
  end

  @spec get_client_id() :: String.t()
  def get_client_id() do
    Application.fetch_env!(:freaky_friday, :spotify_api_client_id)
  end

  @spec gen_random_string() :: String.t()
  def gen_random_string() do
    for _ <- 0..16, into: "" do
      <<Enum.random(?A..?Z)>>
    end
  end
end
