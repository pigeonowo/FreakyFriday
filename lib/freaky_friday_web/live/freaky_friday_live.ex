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
      <div class="min-h-screen">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <!-- Header -->
          <header class="flex items-center justify-between mb-8">
            <div class="flex items-center space-x-3">
              <a href={~p"/"}>
                <h1 class="text-2xl font-semibold">
                  Freaky Friday
                </h1>
              </a>
            </div>

            <div class="flex items-center space-x-4">
              <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/60 dark:bg-slate-800/60 shadow-sm">
                <.icon name="hero-users" class="w-5 h-5 text-slate-700 dark:text-slate-300" />
                <span class="text-sm font-medium text-slate-700 dark:text-slate-200">
                  {@participantcount} Teilnehmer
                </span>
              </div>

              <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/60 dark:bg-slate-800/60 shadow-sm">
                <.icon name="hero-forward" class="w-5 h-5 text-slate-700 dark:text-slate-300" />
                <span class="text-sm font-medium text-slate-700 dark:text-slate-200">
                  2 Skips left
                </span>
              </div>
            </div>
          </header>
          
    <!-- Main grid -->
          <main class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <!-- Current song / player -->
            <section class="md:col-span-2 bg-white dark:bg-slate-800 rounded-lg shadow p-6 flex flex-col sm:flex-row items-center gap-6">
              <div class="w-full sm:w-40 h-40 rounded-md bg-slate-100 dark:bg-slate-700 flex-shrink-0 overflow-hidden flex items-center justify-center">
                <%= case song_art_url(@current_song) do %>
                  <% nil -> %>
                    <.icon
                      name="hero-music-note"
                      class="w-12 h-12 text-slate-400 dark:text-slate-300"
                    />
                  <% url -> %>
                    <img src={url} alt="album art" class="w-full h-full object-cover" />
                <% end %>
              </div>

              <div class="flex-1 w-full">
                <div class="flex items-start justify-between">
                  <div>
                    <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
                      {song_title(@current_song)}
                    </h2>
                    <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
                      {artists_text(@current_song)}
                    </p>
                    <p class="mt-3 text-xs text-slate-500 dark:text-slate-400">
                      Status:
                      <span class="font-medium">
                        {if(@current_song, do: "Playing", else: "Loading...")}
                      </span>
                    </p>
                  </div>

                  <div class="flex flex-col items-end space-y-2 px-4">
                    <.button phx-click="Skip" variant="primary">
                      <.icon name="hero-forward" class="w-4 h-4 mr-2" /> Skip
                    </.button>

                    <.button phx-click="refresh">
                      <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" /> Refresh
                    </.button>
                  </div>
                </div>
              </div>
            </section>
            
    <!-- Participants -->
            <aside class="bg-white dark:bg-slate-800 rounded-lg shadow p-4">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-sm font-medium text-slate-900 dark:text-slate-100">Teilnehmer</h3>
                <span class="text-xs text-slate-500 dark:text-slate-400">{@participantcount}</span>
              </div>

              <div class="space-y-3">
                <div :for={p <- @participants} id={p.participant_id} class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-500 to-rose-400 flex items-center justify-center text-white font-semibold">
                    {initials(p.username)}
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="text-sm font-medium text-slate-900 dark:text-slate-100 truncate">
                      {p.username}
                    </div>
                    <div class="text-xs text-slate-500 dark:text-slate-400 truncate">
                      ID: {p.participant_id}
                    </div>
                  </div>
                </div>

                <div :if={@participants == []} class="text-sm text-slate-500 dark:text-slate-400">
                  Noch keine Teilnehmer online.
                </div>
              </div>
            </aside>
          </main>
          
    <!-- Footer / small notes -->
          <footer class="mt-8 text-xs text-slate-500 dark:text-slate-400">
            Tippe auf "Skip", um zum nächsten Song zu springen. Status wird alle {inspect(
              @poll_interval || 5000
            )}ms aktualisiert.
          </footer>
        </div>
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
            |> assign(:poll_interval, @poll_interval)

          {:ok, socket}
        else
          socket =
            socket
            |> assign(:username, username)
            |> assign(:participant_id, participant_id)
            |> assign(:participantcount, 0)
            |> assign(:participants, [])
            |> assign(:current_song, "Loading....")
            |> assign(:poll_interval, @poll_interval)

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

  # Optional refresh action for mobile button
  def handle_event("refresh", _params, socket) do
    send(self(), :update_song)
    {:noreply, put_flash(socket, :info, "Refreshing current song...")}
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

  # -----------------------
  # Helpers for rendering
  # -----------------------
  defp song_title(nil), do: "Loading..."
  defp song_title(song) when is_binary(song), do: song

  defp song_title(%{"name" => name}) when is_binary(name), do: name
  defp song_title(%{name: name}) when is_binary(name), do: name
  defp song_title(_), do: "Unknown track"

  defp artists_text(nil), do: ""
  defp artists_text(song) when is_binary(song), do: ""

  defp artists_text(%{"artists" => artists}) when is_list(artists) do
    artists |> Enum.map(&artist_name/1) |> Enum.join(", ")
  end

  defp artists_text(%{artists: artists}) when is_list(artists) do
    artists |> Enum.map(&artist_name/1) |> Enum.join(", ")
  end

  defp artists_text(_), do: ""

  defp artist_name(%{"name" => name}), do: name
  defp artist_name(%{name: name}), do: name
  defp artist_name(name) when is_binary(name), do: name
  defp artist_name(_), do: "Unknown"

  defp song_art_url(nil), do: nil

  defp song_art_url(%{"album" => %{"images" => images}}) when is_list(images) do
    images |> List.first() |> maybe_image_url()
  end

  defp song_art_url(%{album: %{images: images}}) when is_list(images) do
    images |> List.first() |> maybe_image_url()
  end

  defp song_art_url(_), do: nil

  defp maybe_image_url(nil), do: nil
  defp maybe_image_url(%{"url" => url}) when is_binary(url), do: url
  defp maybe_image_url(%{url: url}) when is_binary(url), do: url
  defp maybe_image_url(url) when is_binary(url), do: url
  defp maybe_image_url(_), do: nil

  defp initials(nil), do: ""

  defp initials(username) when is_binary(username) do
    username
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.slice(&1, 0, 1))
    |> Enum.join()
    |> String.upcase()
  end
end
