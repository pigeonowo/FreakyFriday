defmodule FreakyFridayWeb.FreakyFridayLIVE do
  use FreakyFridayWeb, :live_view
  alias FreakyFriday.Cache
  alias FreakyFriday.Room
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
      <br />
      <br />
      <br />
      <h2>Teilnehmer:</h2>
      <div :for={p <- @participants}>
        {p.username}
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, session, socket) do
    participant_id = Map.get(session, "participant_id")
    username = Map.get(session, "username")

    case participant_id do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      _ ->
        if connected?(socket) do
          access_token = Cache.get_access_token()

          current_song = FreakyFriday.SpotifyApi.get_current_song!(access_token)

          Phoenix.PubSub.subscribe(FreakyFriday.PubSub, "freaky_friday")

          {:ok, _} =
            FreakyFridayWeb.Presence.track(self(), "freaky_friday", participant_id, %{
              participant_id: participant_id,
              username: username
            })

          schedule_poll()

          socket =
            socket
            |> assign(:username, username)
            |> assign(:participant_id, participant_id)
            |> assign(:participantcount, 0)
            |> assign(:participants, [])
            |> assign(:current_song, current_song)

          {:ok, socket}
        else
          socket =
            socket
            |> assign(:username, username)
            |> assign(:participant_id, participant_id)
            |> assign(:participantcount, 0)
            |> assign(:participants, [])
            |> assign(:current_song, "Loading....")

          {:ok, socket}
        end
    end
  end

  def handle_event("next", _params, socket) do
    Room.skip(socket.assigns.participant_id)

    Phoenix.PubSub.broadcast(
      FreakyFriday.PubSub,
      "freaky_friday",
      {:skipped, socket.assigns.username}
    )

    {:noreply, socket}
  end

  def handle_info({:skipped, username}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{username} pressed skip!")

    {:noreply, socket}
  end

  def handle_info(:update_song, socket) do
    access_token = Cache.get_access_token()

    current_song = SpotifyApi.get_current_song!(access_token)

    schedule_poll()

    socket =
      socket
      |> assign(:current_song, current_song)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    count = get_connected_count()
    participants = get_connected_participants()

    handle_presence_diff(diff)

    {:noreply,
     socket
     |> update(:participantcount, fn _ -> count end)
     |> update(:participants, fn _ -> participants end)}
  end

  # ------------
  def schedule_poll() do
    Process.send_after(self(), :update_song, @poll_interval)
  end

  def handle_presence_diff(%{leaves: leaves}) do
    # handle leaves
    IO.inspect(leaves)

    for {p_id, _} <- leaves do
      Room.leave(p_id)
    end
  end

  def get_connected_count() do
    FreakyFridayWeb.Presence.list("freaky_friday")
    |> Enum.count()
  end

  def get_connected_participants() do
    FreakyFridayWeb.Presence.list("freaky_friday")
    |> Enum.map(fn {_key, value} -> value.metas end)
    |> List.flatten()
  end
end
