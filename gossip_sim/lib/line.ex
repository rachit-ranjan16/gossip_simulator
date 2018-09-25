defmodule Line do
  use GenServer
  # TODO i and j are irrelevant and can be removed 
  def init([id, n, algorithm]) do
    neighbors = get_neighbors(id, n)

    case algorithm do
      # [ status, rec_count, sent_count, n, self_number_id | neighbors ]
      "gossip" ->
        {:ok, [Active, 0, 0, n, id | neighbors]}

        #   "pushsum" -> {:ok, [Active,0, 0, 0, 0, id, 1, n, x| neighbors] } #[status, rec_count,streak,prev_s_w,to_terminate, s, w, n, self_number_id | neighbors ]
    end
  end

  def get_node_name(i) do
    id = i |> Integer.to_string() |> String.pad_leading(4, "0")
    # IO.puts ("Elixir.N1" <> id) |> String.to_atom 
    ("Elixir.N" <> id) |> String.to_atom()
  end

  def get_neighbors(id, n) do
    # TODO REMOVE LOG 
    case id do
      1 -> [get_node_name(n), get_node_name(2)]
      ^n -> [get_node_name(n - 1), get_node_name(1)]
      _ -> [get_node_name(id - 1), get_node_name(id + 1)]
    end
  end

  def create(n, algorithm) do
    nodes =
      for i <- 1..n do
        GenServer.start_link(Line, [i, n, algorithm], name: get_node_name(i))
      end
  end

  # Sync Call to check status of a node 
  def handle_call(:is_active, _from, state) do
    {status, n, id} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, n, id | neighbors] -> {status, n, id}
        # Gossip
        [status, count, sent, n, id | neighbors] -> {status, n, id}
      end

    case status == Active do
      true ->
        {:reply, status, state}

      false ->
        length = round(Float.ceil(:math.sqrt(n)))
        i = rem(id - 1, length) + 1
        j = round(Float.floor((id - 1) / length)) + 1
        {:reply, [{i, j}], state}
    end
  end

  # Deactivate Node
  def handle_cast({:deactivate, _}, [status | tail]) do
    {:noreply, [Inactive | tail]}
  end

  # Remove inactive node from network
  def handle_cast({:remove_mate, node}, state) do
    new_state = List.delete(state, node)
    {:noreply, new_state}
  end

  # NODE : ADD another node to replace inactive node
  def handle_cast({:add_new_mate, node}, state) do
    {:noreply, state ++ [node]}
  end

  # GOSSIP - RECIEVE Main 
  def handle_cast({:gossip, _received}, [status, count, sent, n, id | neighbors] = state) do
    # TODO Remove Log 
    # IO.puts "Starting Gossip with neighbors=#{Kernel.inspect neighbors}"
    length = round(Float.ceil(:math.sqrt(n)))
    i = rem(id - 1, length) + 1
    j = round(Float.floor((id - 1) / length)) + 1
    # IO.puts Kernel.inspect self()
    # IO.puts count

    case count < 200 do
      true ->
        GenServer.cast(Master, {:received, [{i, j}]})
        gossip(id, neighbors, self(), n, i, j)

      false ->
        # Tell Master that gossip is complete and thread is hibernating 
        GenServer.cast(Master, {:hibernated, [{i, j}]})
    end

    {:noreply, [status, count + 1, sent, n, id | neighbors]}
  end

  # GOSSIP  - SEND Main
  def gossip(id, neighbors, pid, n, i, j) do
    target = Enum.random(neighbors)

    case GenServer.call(target, :is_active) do
      Active ->
        GenServer.cast(target, {:gossip, :_sending})

      ina_xy ->
        GenServer.cast(Master, {:node_inactive, ina_xy})
        new_neighbor = GenServer.call(Master, :handle_node_failure)
        GenServer.cast(self(), {:remove_neighbor, target})
        GenServer.cast(self(), {:add_new_neighbor, new_neighbor})
        GenServer.cast(new_neighbor, {:add_new_neighbor, get_node_name(id)})
        GenServer.cast(self(), {:retry_gossip, {pid, i, j}})
    end
  end
end
