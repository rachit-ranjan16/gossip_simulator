defmodule Torus do
  use GenServer
  # TODO i and j are irrelevant and can be removed 
  def init([x, y, z, size, algorithm]) do
    neighbors = get_neighbors(x, y, z, size)

    case algorithm do
      # [ status, rec_count, sent_count, n, self_number_id | neighbors ]
      "gossip" ->
        {:ok, [Active, 0, 0, size, x, y, z | neighbors]}

        #   "pushsum" -> {:ok, [Active,0, 0, 0, 0, id, 1, n, x| neighbors] } #[status, rec_count,streak,prev_s_w,to_terminate, s, w, n, self_number_id | neighbors ]
    end
  end

  def get_node_name(x, y, z) do
    x_ = x |> Integer.to_string() |> String.pad_leading(2, "#")
    y_ = y |> Integer.to_string() |> String.pad_leading(2, "#")
    z_ = z |> Integer.to_string() |> String.pad_leading(2, "#")
    ("Elixir.N000" <> x_ <> y_ <> z_) |> String.to_atom()
  end

  def get_neighbors(x, y, z, size) do
    # 3D Torus Topology - All nodes have 6 neighbors   
    case {x, y, z} do
      # Nodes on vertices with three neighbors each
      {0, 0, 0} ->
        [
          get_node_name(1, 0, 0),
          get_node_name(0, 1, 0),
          get_node_name(0, 0, 1),
          get_node_name(size, 0, 0),
          get_node_name(0, 0, size),
          get_node_name(0, size, 0)
        ]

      {^size, ^size, ^size} ->
        [
          get_node_name(size - 1, size, size),
          get_node_name(size, size - 1, size),
          get_node_name(size, size, size - 1),
          get_node_name(0, size, size),
          get_node_name(size, 0, size),
          get_node_name(size, size, 0)
        ]

      {0, 0, ^size} ->
        [
          get_node_name(1, 0, size),
          get_node_name(0, 1, size),
          get_node_name(0, 0, size - 1),
          get_node_name(0, size, size),
          get_node_name(size, 0, size),
          get_node_name(0, 0, 0)
        ]

      {0, ^size, 0} ->
        [
          get_node_name(0, size, 1),
          get_node_name(0, size, 1),
          get_node_name(0, size - 1, 0),
          get_node_name(0, size, size),
          get_node_name(size, size, 0),
          get_node_name(0, 0, 0)
        ]

      {^size, 0, 0} ->
        [
          get_node_name(size - 1, 0, 0),
          get_node_name(size, 1, 0),
          get_node_name(size, 0, 1),
          get_node_name(size, size, 0),
          get_node_name(size, 0, size),
          get_node_name(0, 0, 0)
        ]

      {^size, ^size, 0} ->
        [
          get_node_name(size - 1, size, 0),
          get_node_name(size, size - 1, 0),
          get_node_name(size, size, 1),
          get_node_name(0, size, 0),
          get_node_name(size, 0, 0),
          get_node_name(size, size, size)
        ]

      {^size, 0, ^size} ->
        [
          get_node_name(size - 1, 0, size),
          get_node_name(size, 1, size),
          get_node_name(size, 0, size - 1),
          get_node_name(size, 0, 0),
          get_node_name(0, 0, size),
          get_node_name(size, size, 0)
        ]

      {0, ^size, ^size} ->
        [
          get_node_name(1, size, size),
          get_node_name(0, size - 1, size),
          get_node_name(0, size, size - 1),
          get_node_name(0, size, 0),
          get_node_name(0, 0, size),
          get_node_name(size, size, size)
        ]

      # Nodes on edge lines with four neighbors each
      {_, ^size, ^size} ->
        [
          get_node_name(x - 1, size, size),
          get_node_name(x + 1, size, size),
          get_node_name(x, size - 1, size),
          get_node_name(x, size, size - 1),
          get_node_name(x, 0, size),
          get_node_name(x, size, 0)
        ]

      {^size, _, ^size} ->
        [
          get_node_name(size, y - 1, size),
          get_node_name(size, y + 1, size),
          get_node_name(size - 1, y, size),
          get_node_name(size, y, size - 1),
          get_node_name(size, y, 0),
          get_node_name(0, y, size)
        ]

      {^size, ^size, _} ->
        [
          get_node_name(size, size, z - 1),
          get_node_name(size, size, z + 1),
          get_node_name(size - 1, size, z),
          get_node_name(size, size - 1, z),
          get_node_name(0, size, z),
          get_node_name(size, 0, z)
        ]

      {0, ^size, _} ->
        [
          get_node_name(1, size, z),
          get_node_name(0, size, z - 1),
          get_node_name(0, size, z + 1),
          get_node_name(0, size - 1, z),
          get_node_name(size, size, z),
          get_node_name(0, 0, z)
        ]

      {0, _, ^size} ->
        [
          get_node_name(1, y, size),
          get_node_name(0, y - 1, size),
          get_node_name(0, y + 1, size),
          get_node_name(0, y, size - 1),
          get_node_name(size, y, size),
          get_node_name(0, y, 0)
        ]

      {_, 0, ^size} ->
        [
          get_node_name(x, 1, size),
          get_node_name(x - 1, 0, size),
          get_node_name(x + 1, 0, size),
          get_node_name(x, 0, size - 1),
          get_node_name(x, size, size),
          get_node_name(x, 0, 0)
        ]

      {_, ^size, 0} ->
        [
          get_node_name(x, size, 1),
          get_node_name(x - 1, size, 0),
          get_node_name(x + 1, size, 0),
          get_node_name(x, size - 1, 0),
          get_node_name(x, size, size),
          get_node_name(x, 0, 0)
        ]

      {^size, 0, _} ->
        [
          get_node_name(size, 1, z),
          get_node_name(size, 0, z - 1),
          get_node_name(size, 0, z + 1),
          get_node_name(size - 1, 0, z),
          get_node_name(size, y, 0),
          get_node_name(0, y, size)
        ]

      {^size, _, 0} ->
        [
          get_node_name(size, y, 1),
          get_node_name(size, y - 1, 0),
          get_node_name(size, y + 1, 0),
          get_node_name(size - 1, y, 0),
          get_node_name(size, y, size),
          get_node_name(0, y, 0)
        ]

      {0, 0, _} ->
        [
          get_node_name(0, 1, z),
          get_node_name(1, 0, z),
          get_node_name(0, 0, z - 1),
          get_node_name(0, 0, z + 1),
          get_node_name(0, size, z),
          get_node_name(size, 0, z)
        ]

      {0, _, 0} ->
        [
          get_node_name(0, y, 1),
          get_node_name(1, y, 0),
          get_node_name(0, y - 1, 0),
          get_node_name(0, y + 1, 0),
          get_node_name(0, y, size),
          get_node_name(size, y, 0)
        ]

      {_, 0, 0} ->
        [
          get_node_name(x, 1, 0),
          get_node_name(x, 0, 1),
          get_node_name(x - 1, 0, 0),
          get_node_name(x + 1, 0, 0),
          get_node_name(x, 0, size),
          get_node_name(x, size, 0)
        ]

      # Nodes on the cube face with 5 neighbors each 
      {_, _, 0} ->
        [
          get_node_name(x - 1, y, 0),
          get_node_name(x, y - 1, 0),
          get_node_name(x + 1, y, 0),
          get_node_name(x, y + 1, 0),
          get_node_name(x, y, 1),
          get_node_name(x, y, size)
        ]

      {_, 0, _} ->
        [
          get_node_name(x - 1, 0, z),
          get_node_name(x + 1, 0, z),
          get_node_name(x, 0, z - 1),
          get_node_name(x, 0, z + 1),
          get_node_name(x, 1, z),
          get_node_name(x, size, z)
        ]

      {0, _, _} ->
        [
          get_node_name(1, y, z),
          get_node_name(0, y + 1, z),
          get_node_name(0, y - 1, z),
          get_node_name(0, y, z + 1),
          get_node_name(0, y, z - 1),
          get_node_name(size, y, z)
        ]

      {_, _, ^size} ->
        [
          get_node_name(x, y, size - 1),
          get_node_name(x - 1, y, size),
          get_node_name(x + 1, y, size),
          get_node_name(x, y - 1, size),
          get_node_name(x, y + 1, size),
          get_node_name(x, y, 0)
        ]

      {_, ^size, _} ->
        [
          get_node_name(x, size - 1, z),
          get_node_name(x - 1, size, z),
          get_node_name(x + 1, size, z),
          get_node_name(x, size, z + 1),
          get_node_name(x, size, z - 1),
          get_node_name(x, 0, z)
        ]

      {^size, _, _} ->
        [
          get_node_name(size - 1, y, z),
          get_node_name(size, y - 1, z),
          get_node_name(size, y + 1, z),
          get_node_name(size, y, z + 1),
          get_node_name(size, y, z - 1),
          get_node_name(0, y, z)
        ]

      # Every other node in the cube body with 6 neighbors  
      _ ->
        [
          get_node_name(x - 1, y, z),
          get_node_name(x + 1, y, z),
          get_node_name(x, y - 1, z),
          get_node_name(x, y + 1, z),
          get_node_name(x, y, z - 1),
          get_node_name(x, y, z + 1)
        ]
    end
  end

  def create(size, algorithm) do
    nodes =
      for i <- 0..size do
        for j <- 0..size do
          for k <- 0..size do
            GenServer.start_link(Torus, [i, j, k, size, algorithm], name: get_node_name(i, j, k))
          end
        end
      end
  end

  # Sync Call to check status of a node 
  def handle_call(:is_active, _from, state) do
    {status, n, x, y, z} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, n, x, y, z | neighbors] -> {status, n, x, y, z}
        # Gossip
        [status, count, sent, n, x, y, z | neighbors] -> {status, n, x, y, z}
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
  def handle_cast({:gossip, _received}, [status, count, sent, n, x, y, z | neighbors] = state) do
    length = round(Float.ceil(:math.sqrt(n)))
    i = rem(x + y + z - 1, length) + 1
    j = round(Float.floor((x + y + z - 1) / length)) + 1

    if count < 100 do
      GenServer.cast(Master, {:received, [{i, j}]})
      gossip(x, y, z, neighbors, self(), n, i, j)
    else
      # Tell Master that gossip is complete and thread is hibernating 
      GenServer.cast(Master, {:hibernated, [{i, j}]})
    end

    {:noreply, [status, count + 1, sent, n, x, y, z | neighbors]}
  end

  # GOSSIP  - SEND Main
  def gossip(x, y, z, neighbors, pid, n, i, j) do
    target = Enum.random(neighbors)

    case GenServer.call(target, :is_active) do
      Active ->
        GenServer.cast(target, {:gossip, :_sending})

      ina_xy ->
        GenServer.cast(Master, {:node_inactive, ina_xy})
        new_neighbor = GenServer.call(Master, :handle_node_failure)
        GenServer.cast(self(), {:remove_neighbor, target})
        GenServer.cast(self(), {:add_new_neighbor, new_neighbor})
        GenServer.cast(new_neighbor, {:add_new_neighbor, get_node_name(x, y, z)})
        GenServer.cast(self(), {:retry_gossip, {pid, i, j}})
    end
  end
end
