defmodule FreakyFridayWeb.FreakyFridayLIVE do
  use FreakyFridayWeb, :live_view
  alias FreakyFriday.SpotifyApi

  # 5000 ms
  @poll_interval 5_000

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= if @current_song do %>
        Current Song playing: {@current_song}
        <.button phx-click="next">
          Next
        </.button>
      <% end %>
    </Layouts.app>
    """
  end

  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id")

    case user_id do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      _ ->
        if connected?(socket) do
          user = FreakyFriday.User.get_by_id!(user_id)

          {access_token, r_tok, e_at} =
            FreakyFriday.SpotifyApi.refresh_token(user.refresh_token)

          user =
            if r_tok do
              cs = FreakyFriday.User.changeset(user, %{refresh_token: r_tok, expires_at: e_at})
              FreakyFriday.Repo.update!(cs)
            else
              user
            end

          current_song = FreakyFriday.SpotifyApi.get_current_song!(access_token)

          Phoenix.PubSub.subscribe(FreakyFriday.PubSub, "freaky_friday")
          schedule_poll()

          socket =
            socket
            |> assign(:user, user)
            |> assign(:access_token, access_token)
            |> assign(:current_song, current_song)

          {:ok, socket}
        else
          socket =
            socket
            |> assign(:user, nil)
            |> assign(:access_token, nil)
            |> assign(:current_song, "Loading....")

          {:ok, socket}
        end
    end
  end

  def handle_event("next", _params, socket) do
    access_token =
      if SpotifyApi.token_needs_refresh?(socket.assigns.user.expires_at) do
        FreakyFriday.update_token(socket.assigns.user)
      else
        socket.assigns.access_token
      end

    # skip and then assign current_song again
    SpotifyApi.skip!(access_token)

    Phoenix.PubSub.broadcast(FreakyFriday.PubSub, "freaky_friday", :skipped)

    socket =
      socket
      |> assign(:access_token, access_token)

    {:noreply, socket}
  end

  def handle_info(:skipped, socket) do
    socket =
      socket
      |> put_flash(:info, "#{socket.assigns.user.username} pressed skip!")

    {:noreply, socket}
  end

  def handle_info(:update_song, socket) do
    access_token =
      if SpotifyApi.token_needs_refresh?(socket.assigns.user.expires_at) do
        FreakyFriday.update_token(socket.assigns.user)
      else
        socket.assigns.access_token
      end

    current_song = SpotifyApi.get_current_song!(access_token)

    schedule_poll()

    socket =
      socket
      |> assign(:access_token, access_token)
      |> assign(:current_song, current_song)

    {:noreply, socket}
  end

  def schedule_poll() do
    Process.send_after(self(), :update_song, @poll_interval)
  end
end
