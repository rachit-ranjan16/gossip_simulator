defmodule Grid3D do
  use GenServer

  def init([x, y, z, size, algorithm]) do
    neighbors = get_neighbors(x, y, z, size)

    case algorithm do
      "gossip" ->
        {:ok, [Active, 0, 0, size, x, y, z | neighbors]}

      "pushsum" ->
        {:ok, [Active, 0, 0, 0, 0, x, 1, size, x, y, z | neighbors]}
    end
  end

  def get_node_name(x, y, z) do
    x_ = x |> Integer.to_string() |> String.pad_leading(2, "#")
    y_ = y |> Integer.to_string() |> String.pad_leading(2, "#")
    z_ = z |> Integer.to_string() |> String.pad_leading(2, "#")
    ("Elixir.N000" <> x_ <> y_ <> z_) |> String.to_atom()
  end

  def get_neighbors(x, y, z, size) do
    # 3D Grid/Cube 
    # Vertex and on-edge nodes are have 4 neighbors 
    # Edge nodes have 4 neighbors 
    # Face nodes have 5 neighbors 
    # All other nodes have 6 neighbors     
    case {x, y, z} do
      # Nodes on vertices with three neighbors each
      {0, 0, 0} ->
        [get_node_name(1, 0, 0), get_node_name(0, 1, 0), get_node_name(0, 0, 1)]

      {^size, ^size, ^size} ->
        [
          get_node_name(size - 1, size, size),
          get_node_name(size, size - 1, size),
          get_node_name(size, size, size - 1)
        ]

      {0, 0, ^size} ->
        [
          get_node_name(1, 0, size),
          get_node_name(0, 1, size),
          get_node_name(0, 0, size - 1)
        ]

      {0, ^size, 0} ->
        [
          get_node_name(0, size, 1),
          get_node_name(0, size, 1),
          get_node_name(0, size - 1, 0)
        ]

      {^size, 0, 0} ->
        [
          get_node_name(size - 1, 0, 0),
          get_node_name(size, 1, 0),
          get_node_name(size, 0, 1)
        ]

      {^size, ^size, 0} ->
        [
          get_node_name(size - 1, size, 0),
          get_node_name(size, size - 1, 0),
          get_node_name(size, size, 1)
        ]

      {^size, 0, ^size} ->
        [
          get_node_name(size - 1, 0, size),
          get_node_name(size, 1, size),
          get_node_name(size, 0, size - 1)
        ]

      {0, ^size, ^size} ->
        [
          get_node_name(1, size, size),
          get_node_name(0, size - 1, size),
          get_node_name(0, size, size - 1)
        ]

      # Nodes on edge lines with four neighbors each
      {_, ^size, ^size} ->
        [
          get_node_name(x - 1, size, size),
          get_node_name(x + 1, size, size),
          get_node_name(x, size - 1, size),
          get_node_name(x, size, size - 1)
        ]

      {^size, _, ^size} ->
        [
          get_node_name(size, y - 1, size),
          get_node_name(size, y + 1, size),
          get_node_name(size - 1, y, size),
          get_node_name(size, y, size - 1)
        ]

      {^size, ^size, _} ->
        [
          get_node_name(size, size, z - 1),
          get_node_name(size, size, z + 1),
          get_node_name(size - 1, size, z),
          get_node_name(size, size - 1, z)
        ]

      {0, ^size, _} ->
        [
          get_node_name(1, size, z),
          get_node_name(0, size, z - 1),
          get_node_name(0, size, z + 1),
          get_node_name(0, size - 1, z)
        ]

      {0, _, ^size} ->
        [
          get_node_name(1, y, size),
          get_node_name(0, y - 1, size),
          get_node_name(0, y + 1, size),
          get_node_name(0, y, size - 1)
        ]

      {_, 0, ^size} ->
        [
          get_node_name(x, 1, size),
          get_node_name(x - 1, 0, size),
          get_node_name(x + 1, 0, size),
          get_node_name(x, 0, size - 1)
        ]

      {_, ^size, 0} ->
        [
          get_node_name(x, size, 1),
          get_node_name(x - 1, size, 0),
          get_node_name(x + 1, size, 0),
          get_node_name(x, size - 1, 0)
        ]

      {^size, 0, _} ->
        [
          get_node_name(size, 1, z),
          get_node_name(size, 0, z - 1),
          get_node_name(size, 0, z + 1),
          get_node_name(size - 1, 0, z)
        ]

      {^size, _, 0} ->
        [
          get_node_name(size, y, 1),
          get_node_name(size, y - 1, 0),
          get_node_name(size, y + 1, 0),
          get_node_name(size - 1, y, 0)
        ]

      {0, 0, _} ->
        [
          get_node_name(0, 1, z),
          get_node_name(1, 0, z),
          get_node_name(0, 0, z - 1),
          get_node_name(0, 0, z + 1)
        ]

      {0, _, 0} ->
        [
          get_node_name(0, y, 1),
          get_node_name(1, y, 0),
          get_node_name(0, y - 1, 0),
          get_node_name(0, y + 1, 0)
        ]

      {_, 0, 0} ->
        [
          get_node_name(x, 1, 0),
          get_node_name(x, 0, 1),
          get_node_name(x - 1, 0, 0),
          get_node_name(x + 1, 0, 0)
        ]

      # Nodes on the cube face with 5 neighbors each 
      {_, _, 0} ->
        [
          get_node_name(x - 1, y, 0),
          get_node_name(x, y - 1, 0),
          get_node_name(x + 1, y, 0),
          get_node_name(x, y + 1, 0),
          get_node_name(x, y, 1)
        ]

      {_, 0, _} ->
        [
          get_node_name(x - 1, 0, z),
          get_node_name(x + 1, 0, z),
          get_node_name(x, 0, z - 1),
          get_node_name(x, 0, z + 1),
          get_node_name(x, 1, z)
        ]

      {0, _, _} ->
        [
          get_node_name(1, y, z),
          get_node_name(0, y + 1, z),
          get_node_name(0, y - 1, z),
          get_node_name(0, y, z + 1),
          get_node_name(0, y, z - 1)
        ]

      {_, _, ^size} ->
        [
          get_node_name(x, y, size - 1),
          get_node_name(x - 1, y, size),
          get_node_name(x + 1, y, size),
          get_node_name(x, y - 1, size),
          get_node_name(x, y + 1, size)
        ]

      {_, ^size, _} ->
        [
          get_node_name(x, size - 1, z),
          get_node_name(x - 1, size, z),
          get_node_name(x + 1, size, z),
          get_node_name(x, size, z + 1),
          get_node_name(x, size, z - 1)
        ]

      {^size, _, _} ->
        [
          get_node_name(size - 1, y, z),
          get_node_name(size, y - 1, z),
          get_node_name(size, y + 1, z),
          get_node_name(size, y, z + 1),
          get_node_name(size, y, z - 1)
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
            GenServer.start_link(Grid3D, [i, j, k, size, algorithm], name: get_node_name(i, j, k))
          end
        end
      end
  end

  # Sync Call to check status of a node 
  def handle_call(:is_active, _from, state) do
    {status, size, x, y, z} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, size, x, y, z | neighbors] ->
          {status, size, x, y, z}

        # Gossip
        [status, count, sent, size, x, y, z | neighbors] ->
          {status, size, x, y, z}
      end

    case status == Active do
      true ->
        {:reply, status, state}

      false ->
        nil
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

  # GOSSIP - RECIEVE 
  def handle_cast({:gossip, _received}, [status, count, sent, size, x, y, z | neighbors] = state) do
    i = 0
    j = 0

    if count < 100 do
      GenServer.cast(Master, {:received, [{i, j}]})
      gossip(x, y, z, neighbors, self(), size, i, j)
    else
      # Tell Master that gossip is complete and thread is hibernating 
      GenServer.cast(Master, {:hibernated, [{i, j}]})
    end

    {:noreply, [status, count + 1, sent, size, x, y, z | neighbors]}
  end

  # GOSSIP  - SEND
  def gossip(x, y, z, neighbors, pid, size, i, j) do
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

  # PUSHSUM - RECIEVE
  def handle_cast(
        {:pushsum, {rec_s, rec_w}},
        [status, count, streak, prev_s_w, term, s, w, size, x, y, z | neighbors] = state
      ) do
    length = round(Float.ceil(:math.sqrt(size)))
    i = 0
    j = 0
    GenServer.cast(Master, {:received, [{i, j}]})

    case abs((s + rec_s) / (w + rec_w) - prev_s_w) < :math.pow(10, -10) do
      false ->
        push_sum(x, y, z, (s + rec_s) / 2, (w + rec_w) / 2, neighbors, self(), i, j)

        {:noreply,
         [
           status,
           count + 1,
           0,
           (s + rec_s) / (w + rec_w),
           term,
           (s + rec_s) / 2,
           (w + rec_w) / 2,
           size,
           x,
           y,
           z | neighbors
         ]}

      true ->
        case streak + 1 == 3 do
          true ->
            GenServer.cast(Master, {:hibernated, [{i, j}]})

            {:noreply,
             [
               status,
               count + 1,
               streak + 1,
               (s + rec_s) / (w + rec_w),
               1,
               s + rec_s,
               w + rec_w,
               size,
               x,
               y,
               z | neighbors
             ]}

          false ->
            push_sum(x, y, z, (s + rec_s) / 2, (w + rec_w) / 2, neighbors, self(), i, j)

            {:noreply,
             [
               status,
               count + 1,
               streak + 1,
               (s + rec_s) / (w + rec_w),
               0,
               (s + rec_s) / 2,
               (w + rec_w) / 2,
               size,
               x,
               y,
               z | neighbors
             ]}
        end
    end
  end

  # PUSHSUM - SEND 
  def push_sum(x, y, z, s, w, neighbors, pid, i, j) do
    target = Enum.random(neighbors)

    case GenServer.call(target, :is_active) do
      Active ->
        GenServer.cast(target, {:pushsum, {s, w}})

      ina_xy ->
        GenServer.cast(Master, {:node_inactive, ina_xy})
        new_neighbor = GenServer.call(Master, :handle_node_failure)
        GenServer.cast(self(), {:remove_neighbor, target})
        GenServer.cast(self(), {:add_new_neighbor, new_neighbor})
        GenServer.cast(new_neighbor, {:add_new_neighbor, get_node_name(x, y, z)})
    end
  end
end
