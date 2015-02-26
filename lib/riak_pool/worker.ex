defmodule RiakPool.Worker do
  use Supervisor
  @behaviour :poolboy_worker

  defmodule State do
    defstruct connection: :undefined,
              address:    :undefined,
              port:       :undefined,
              options:    [],
              timer:      :undefined
  end

  def start_link([address, port, options]) do
    :gen_server.start_link(__MODULE__, [address, port, options], [])
  end


  def init([address, port, options]) do
    :erlang.process_flag(:trap_exit, true)
    state = %State{address: address, port: port, options: options}
    {:ok, connect(state)}
  end


  def handle_call({:run, worker_function}, _from, state) do
    result = :erlang.apply(worker_function, [state.connection])
    {:reply, result, state}
  end

  def handle_call(_msg, _from, state) do
    IO.inspect "very generic"
    {:reply, "test", state}
  end

  defp connect(state) do
    # First, cancel any timers
    if state.timer != :undefined do
      :erlang.cancel_timer(state.timer)
    end

    # Set timer as undefined
    new_state = %__MODULE__.State{state| timer: :undefined}
    connection_options = Dict.get(state.options, :connection_options, [])

    case :riakc_pb_socket.start_link(state.address, state.port, connection_options) do
      {:ok, connection} ->
        connected_state = %__MODULE__.State{state| connection: connection}
      {:error, _reason} ->
        faulty_state = %__MODULE__.State{state| connection: :undefined}
        timer = :erlang.send_after(state.options[:retry_interval], self, :reconnect)
        faulty_state.timer(timer)
    end
  end


  def handle_info({:EXIT, _pid, _reason}, state) do
    new_state = %__MODULE__.State{state| connection: :undefined}
    timer = :erlang.send_after(state.options[:retry_interval], self, :reconnect)
    {:noreply, new_state.timer(timer)}
  end


  def handle_info(:reconnect, state) do
    new_state = connect(state)
    {:noreply, new_state}
  end
end
