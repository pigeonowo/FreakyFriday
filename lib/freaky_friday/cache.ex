defmodule FreakyFriday.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    a_tok = ""

    r_tok = ""

    {:ok, {a_tok, r_tok, DateTime.now!("Etc/UTC")}}
  end

  def get_access_token() do
    GenServer.call(__MODULE__, :get_access_token)
  end

  def set_refresh_token(r_tok, e_at) do
    GenServer.cast(__MODULE__, {:set_refresh_token, r_tok, e_at})
  end

  @impl true
  def handle_call(:get_access_token, _from, {a_tok, r_tok, e_at} = state) do
    if FreakyFriday.SpotifyApi.token_needs_refresh?(e_at) do
      {access_token, refresh_token, e_at} = FreakyFriday.SpotifyApi.refresh_token(r_tok)
      {:reply, access_token, {access_token, refresh_token, e_at}}
    else
      {:reply, a_tok, state}
    end
  end

  @impl true
  def handle_cast({:set_refresh_token, r_tok, _e_at}, _state) do
    {access_token, refresh_token, e_at} = FreakyFriday.SpotifyApi.refresh_token(r_tok)
    {:noreply, {access_token, refresh_token, e_at}}
  end
end
