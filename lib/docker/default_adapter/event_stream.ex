defmodule Docker.DefaultAdapter.EventStream do
  @moduledoc false

  use GenServer

  @version "v1.41"
  @client Application.compile_env(:docker, :client, Docker.Client)

  @derive {Inspect, only: []}
  @enforce_keys [:pid]
  defstruct [:pid]

  @doc false
  @spec child_spec(Enumerable.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    query = Access.get(opts, :query, %{})
    owner = Access.get(opts, :heir, self())

    %{
      id: {__MODULE__, make_ref()},
      start: {GenServer, :start_link, [__MODULE__, %{query: query, owner: owner}, []]},
      restart: :transient
    }
  end

  @impl GenServer
  def init(init_arg) do
    state = %{
      stream: nil,
      monitor: nil,
      query: init_arg.query,
      owner: init_arg.owner
    }

    {:ok, state, {:continue, :monitor}}
  end

  @impl GenServer
  def handle_continue(msg, state)

  def handle_continue(:monitor, %{monitor: nil, owner: owner} = state) do
    monitor = Process.monitor(owner)

    {:noreply, %{state | monitor: monitor}, {:continue, :stream}}
  end

  def handle_continue(:stream, %{stream: nil, query: query} = state) do
    case @client.async_request(:get, [@version, "events"], query: query) do
      {:ok, stream} ->
        {:noreply, %{state | stream: stream}}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  @impl GenServer
  def handle_call(msg, from, state)

  def handle_call({:give_away, heir}, _from, state) do
    Process.demonitor(state.monitor)
    monitor = Process.monitor(heir)

    {:reply, :ok, %{state | owner: heir, monitor: monitor}}
  end

  def handle_call(:close, _from, state) do
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(msg, state)

  def handle_info({:hackney_response, stream, :done}, %{stream: stream} = state) do
    send(stream.owner, {:docker_events, :done})

    {:stop, :normal, %{state | stream: nil}}
  end

  def handle_info({:hackney_response, stream, msg}, %{stream: stream} = state) do
    event =
      msg
      |> Jason.decode!()
      |> Docker.DefaultAdapter.map_event()

    send(stream.owner, {:docker_events, event})

    {:noreply, state}
  end

  @impl GenServer
  def terminate(reason, state)

  def terminate(_reason, %{stream: nil}) do
    nil
  end

  def terminate(_reason, %{stream: stream}) when not is_nil(stream) do
    @client.cancel(stream)
  end
end

defimpl Docker.EventStream, for: Docker.DefaultAdapter.EventStream do
  def give_away(%Docker.DefaultAdapter.EventStream{pid: pid}, heir) do
    GenServer.call(pid, {:give_away, heir})
  end

  def close(%Docker.DefaultAdapter.EventStream{pid: pid}) do
    GenServer.call(pid, :close)
  end
end
