defmodule FreakyFriday.Room do
  require Logger
  alias FreakyFriday.Cache
  use GenServer

  @type state :: %{
          host: participantid :: integer() | nil,
          participants: list(FreakyFriday.Participant)
        }

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def join(participant_id) do
    GenServer.cast(__MODULE__, {:join, participant_id})
  end

  def make_host(participantid) do
    GenServer.cast(__MODULE__, {:make_host, participantid})
  end

  def leave(participant_id) do
    GenServer.cast(__MODULE__, {:leave, participant_id})
  end

  def skip(participant_id) do
    GenServer.cast(__MODULE__, {:skip, participant_id})
  end

  def get_skips(participant_id) do
    GenServer.call(__MODULE__, {:get_skips, participant_id})
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(_) do
    {:ok, %{participants: [], host: nil}}
  end

  @impl true
  def handle_cast({:join, participant}, state) do
    {:noreply,
     %{
       state
       | participants: [
           participant | state.participants
         ]
     }}
  end

  def handle_cast({:leave, participant_id}, state) do
    state =
      if state.host == participant_id do
        %{state | host: nil}
      else
        state
      end

    element = Enum.find(state.participants, fn g -> g.id == participant_id end)
    new_participants = List.delete(state.participants, element)
    {:noreply, %{state | participants: new_participants}}
  end

  def handle_cast({:skip, id}, state) do
    Logger.info("Participant #{id} is skipping...")
    index = Enum.find_index(state.participants, fn p -> p.id == id end)

    new_participants =
      if index do
        List.update_at(state.participants, index, fn p -> %{p | skips: max(p.skips - 1, 0)} end)
      else
        state.participants
      end

    Logger.debug("New participants: #{inspect(new_participants)}")

    if state.host do
      Task.start(fn ->
        try do
          Cache.get_access_token()
          |> FreakyFriday.SpotifyApi.skip!()
        rescue
          exception ->
            Logger.error("Spotify skip! raised an exception: #{inspect(exception)}")
        catch
          kind, value ->
            Logger.error("Spotify skip! failed (#{kind}): #{inspect(value)}")
        end
      end)
    end

    new_state = %{state | participants: new_participants}
    {:noreply, new_state}
  end

  def handle_cast({:make_host, participant_id}, state) do
    {:noreply, %{state | host: participant_id}}
  end

  @impl true
  def handle_call(:get_state, _, state) do
    {:reply, state, state}
  end

  def handle_call({:get_skips, participant_id}, _, state) do
    participant = Enum.find(state.participants, fn p -> p.id == participant_id end)

    skips =
      if participant do
        participant.skips
      else
        0
      end

    {:reply, skips, state}
  end
end
