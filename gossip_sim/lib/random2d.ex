defmodule Random2D do
  use GenServer
  # TODO i and j are irrelevant and can be removed 
  def init([x, y, size, algorithm]) do
    neighbors = get_neighbors(x, y, size)
    
    case algorithm do
      # [ status, rec_count, sent_count, n, self_number_id | neighbors ]
      "gossip" ->
        {:ok, [Active, 0, 0, size, x, y | neighbors]}

        #   "pushsum" -> {:ok, [Active,0, 0, 0, 0, id, 1, n, x| neighbors] } #[status, rec_count,streak,prev_s_w,to_terminate, s, w, n, self_number_id | neighbors ]
    end
  end

  def get_node_name(x, y) do
    x_ = x |> Integer.to_string() |> String.pad_leading(2, "#")
    y_ = y |> Integer.to_string() |> String.pad_leading(2, "#")
    ("Elixir.N000" <> x_ <> y_) |> String.to_atom()
  end

  def get_neighbors(x, y, size) do  
    #TODO Decide how to get neighbors 
  end

  def create(size, algorithm) do
    nodes = GenServer.start_link(Random2D, [:rand.uniform(), :random.uniform(), size, algorithm], name: get_node_name(i, j))
          end
        end
      end
  end

  # Sync Call to check status of a node 
  def handle_call(:is_active, _from, state) do
    {status, n, x, y} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, n, x, y | neighbors] -> {status, n, x, y}
        # Gossip
        [status, count, sent, n, x, y| neighbors] -> {status, n, x, y}
      end

    case status == Active do
      true ->
        {:reply, status, state}

      false ->
        nil
        # TODO Figure out what to do here 
        # length = round(Float.ceil(:math.sqrt(n)))
        # i = rem(id - 1, length) + 1
        # j = round(Float.floor((id - 1) / length)) + 1
        # {:reply, [{i, j}], state}
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
  def handle_cast({:gossip, _received}, [status, count, sent, n, x, y | neighbors] = state) do
    length = round(Float.ceil(:math.sqrt(n)))
    i = rem(x + y - 1, length) + 1
    j = round(Float.floor((x + y - 1) / length)) + 1

    if count < 100 do
      GenServer.cast(Master, {:received, [{i, j}]})
      gossip(x, y, neighbors, self(), n, i, j)
    else
      # Tell Master that gossip is complete and thread is hibernating 
      GenServer.cast(Master, {:hibernated, [{i, j}]})
    end

    {:noreply, [status, count + 1, sent, n, x, y | neighbors]}
  end

  # GOSSIP  - SEND Main
  def gossip(x, y, neighbors, pid, n, i, j) do
    target = Enum.random(neighbors)

    case GenServer.call(target, :is_active) do
      Active ->
        GenServer.cast(target, {:gossip, :_sending})

      ina_xy ->
        GenServer.cast(Master, {:node_inactive, ina_xy})
        new_neighbor = GenServer.call(Master, :handle_node_failure)
        GenServer.cast(self(), {:remove_neighbor, target})
        GenServer.cast(self(), {:add_new_neighbor, new_neighbor})
        GenServer.cast(new_neighbor, {:add_new_neighbor, get_node_name(x, y)})
        GenServer.cast(self(), {:retry_gossip, {pid, i, j}})
    end
  end
end
