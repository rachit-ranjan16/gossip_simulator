defmodule Random2D do
  use GenServer
  # TODO i and j are irrelevant and can be removed 
  def init([x, y, size, algorithm, nodes_location]) do
    neighbors = get_neighbors(x, y, nodes_location, [], 0)

    # IO.puts("Node #{x},#{y} #{length(neighbors)}")

    case algorithm do
      # [ status, rec_count, sent_count, n, self_number_id | neighbors ]
      "gossip" ->
        {:ok, [Active, 0, 0, size, x, y | neighbors]}

        #   "pushsum" -> {:ok, [Active,0, 0, 0, 0, id, 1, n, x| neighbors] } #[status, rec_count,streak,prev_s_w,to_terminate, s, w, n, self_number_id | neighbors ]
    end
  end

  def get_node_name(x, y) do
    x_ = x |> Float.to_string() |> String.pad_leading(2, "#")
    y_ = y |> Float.to_string() |> String.pad_leading(2, "#")
    ("Elixir.N000" <> x_ <> y_) |> String.to_atom()
  end

  def get_distance(x1, y1, x2, y2) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  def get_neighbors(x, y, nodes_location, close_ones, i) when i >= length(nodes_location) do
    close_ones
  end

  def get_neighbors(x, y, nodes_location, close_ones, i)
      when i < length(nodes_location) do
    close_ones =
      if get_distance(
           x,
           y,
           elem(Enum.at(nodes_location, i), 0),
           elem(Enum.at(nodes_location, i), 1)
         ) < 0.1 and x != elem(Enum.at(nodes_location, i), 0) and
           y != elem(Enum.at(nodes_location, i), 1) do
        [
          get_node_name(
            elem(Enum.at(nodes_location, i), 0),
            elem(Enum.at(nodes_location, i), 1)
          )
          | close_ones
        ]
      else
        close_ones
      end

    # IO.puts(Kernel.inspect(close_ones))
    get_neighbors(x, y, nodes_location, close_ones, i + 1)
  end

  def populate_node_locations(nodes, n) when n === 0 do
    nodes
  end

  def populate_node_locations(nodes, n) when n > 0 do
    nodes = [{:rand.uniform(), :rand.uniform()} | nodes]
    populate_node_locations(nodes, n - 1)
  end

  def create(size, algorithm) do
    nodes_location = populate_node_locations([], size)
    # IO.puts(Kernel.inspect nodes_location)
    for i <- 0..(size - 1) do
      GenServer.start_link(
        Random2D,
        [
          elem(Enum.at(nodes_location, i), 0),
          elem(Enum.at(nodes_location, i), 1),
          size,
          algorithm,
          nodes_location
        ],
        name:
          get_node_name(
            elem(Enum.at(nodes_location, i), 0),
            elem(Enum.at(nodes_location, i), 1)
          )
      )
    end

    nodes_location
  end

  # Sync Call to check status of a node 
  def handle_call(:is_active, _from, state) do
    {status, n, x, y} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, n, x, y | neighbors] -> {status, n, x, y}
        # Gossip
        [status, count, sent, n, x, y | neighbors] -> {status, n, x, y}
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
    i = 0
    j = 0

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
