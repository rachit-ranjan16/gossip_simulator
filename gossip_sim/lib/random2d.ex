defmodule Random2D do
  use GenServer

  def init([x, y, size, algorithm, nodes_location]) do
    neighbors = get_neighbors(x, y, nodes_location, [], 0)

    case algorithm do
      "gossip" ->
        {:ok, [Active, 0, 0, size, x, y | neighbors]}

      "pushsum" ->
        {:ok, [Active, 0, 0, 0, 0, 0, 1, size, x, y | neighbors]}
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

    get_neighbors(x, y, nodes_location, close_ones, i + 1)
  end

  def populate_node_locations(nodes, size) when size === 0 do
    nodes
  end

  def populate_node_locations(nodes, size) when size > 0 do
    nodes = [{:rand.uniform(), :rand.uniform()} | nodes]
    populate_node_locations(nodes, size - 1)
  end

  def create(size, algorithm) do
    nodes_location = populate_node_locations([], size)

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
    {status, size, x, y} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, size, x, y | neighbors] -> {status, size, x, y}
        # Gossip
        [status, count, sent, size, x, y | neighbors] -> {status, size, x, y}
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
  def handle_cast({:gossip, _received}, [status, count, sent, size, x, y | neighbors] = state) do
    length = round(Float.ceil(:math.sqrt(size)))
    i = 0
    j = 0

    if count < 100 do
      GenServer.cast(Master, {:received, [{i, j}]})
      gossip(x, y, neighbors, self(), size, i, j)
    else
      # Tell Master that gossip is complete and thread is hibernating 
      GenServer.cast(Master, {:hibernated, [{i, j}]})
    end

    {:noreply, [status, count + 1, sent, size, x, y | neighbors]}
  end

  # GOSSIP  - SEND
  def gossip(x, y, neighbors, pid, size, i, j) do
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

  def handle_cast(
        {:pushsum, {rec_s, rec_w}},
        [status, count, streak, prev_s_w, term, s, w, size, x, y | neighbors] = state
      ) do
    length = round(Float.ceil(:math.sqrt(size)))
    i = 0
    j = 0
    GenServer.cast(Master, {:received, [{i, j}]})

    case abs((s + rec_s) / (w + rec_w) - prev_s_w) < :math.pow(10, -10) do
      false ->
        push_sum(x, y, (s + rec_s) / 2, (w + rec_w) / 2, neighbors, self(), i, j)

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
           y | neighbors
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
               y | neighbors
             ]}

          false ->
            push_sum(x, y, (s + rec_s) / 2, (w + rec_w) / 2, neighbors, self(), i, j)

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
               y | neighbors
             ]}
        end
    end
  end

  # PUSHSUM - SEND 
  def push_sum(x, y, s, w, neighbors, pid, i, j) do
    target = Enum.random(neighbors)

    case GenServer.call(target, :is_active) do
      Active ->
        GenServer.cast(target, {:pushsum, {s, w}})

      ina_xy ->
        GenServer.cast(Master, {:node_inactive, ina_xy})
        new_neighbor = GenServer.call(Master, :handle_node_failure)
        GenServer.cast(self(), {:remove_neighbor, target})
        GenServer.cast(self(), {:add_new_neighbor, new_neighbor})
        GenServer.cast(new_neighbor, {:add_new_neighbor, get_node_name(x, y)})
    end
  end
end
