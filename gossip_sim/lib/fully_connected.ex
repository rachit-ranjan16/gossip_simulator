defmodule FullyConnected do
  use GenServer

  def init([id, n, algorithm]) do
    case algorithm do
      "gossip" ->
        {:ok, [Active, 0, 0, n, id]}

      "pushsum" ->
        {:ok, [Active, 0, 0, 0, 0, id, 1, n, id]}
    end
  end

  def get_node_name(i) do
    id = i |> Integer.to_string() |> String.pad_leading(4, "0")
    ("Elixir.N" <> id) |> String.to_atom()
  end

  def get_random_index(n, id) do
    random_index = Enum.random(1..n)

    if random_index === id do
      get_random_index(n, id)
    else
      random_index
    end
  end

  def create(n, algorithm) do
    nodes =
      for i <- 1..n do
        GenServer.start_link(FullyConnected, [i, n, algorithm], name: get_node_name(i))
      end
  end

  # Sync Call to check status of a node 
  def handle_call(:is_active, _from, state) do
    {status, n, id} =
      case state do
        # Push Sum 
        [status, count, streak, prev_s_w, 0, s, w, n, id] -> {status, n, id}
        # Gossip
        [status, count, sent, n, id] -> {status, n, id}
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

  # GOSSIP - RECIEVE
  def handle_cast({:gossip, _received}, [status, count, sent, n, id] = state) do
    length = round(Float.ceil(:math.sqrt(n)))
    i = rem(id - 1, length) + 1
    j = round(Float.floor((id - 1) / length)) + 1

    if count < 100 do
      GenServer.cast(Master, {:received, [{i, j}]})
      gossip(id, self(), n, i, j)
    else
      # Tell Master that gossip is complete and thread is hibernating 
      GenServer.cast(Master, {:hibernated, [{i, j}]})
    end

    {:noreply, [status, count + 1, sent, n, id]}
  end

  # GOSSIP  - SEND
  def gossip(id, pid, n, i, j) do
    # Since every node are connected to every other node, target is randomly chosen 
    target = get_random_index(n, id) |> get_node_name

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

  # PUSHSUM - RECIEVE
  def handle_cast(
        {:pushsum, {rec_s, rec_w}},
        [status, count, streak, prev_s_w, term, s, w, n, id] = state
      ) do
    length = round(Float.ceil(:math.sqrt(n)))
    i = 0
    j = 0
    GenServer.cast(Master, {:received, [{i, j}]})

    case abs((s + rec_s) / (w + rec_w) - prev_s_w) < :math.pow(10, -10) do
      false ->
        push_sum(n, id, (s + rec_s) / 2, (w + rec_w) / 2, self(), i, j)

        {:noreply,
         [
           status,
           count + 1,
           0,
           (s + rec_s) / (w + rec_w),
           term,
           (s + rec_s) / 2,
           (w + rec_w) / 2,
           n,
           id
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
               n,
               id
             ]}

          false ->
            push_sum(n, id, (s + rec_s) / 2, (w + rec_w) / 2, self(), i, j)

            {:noreply,
             [
               status,
               count + 1,
               streak + 1,
               (s + rec_s) / (w + rec_w),
               0,
               (s + rec_s) / 2,
               (w + rec_w) / 2,
               n,
               id
             ]}
        end
    end
  end

  # PUSHSUM - SEND 
  def push_sum(n, id, s, w, pid, i, j) do
    target = get_random_index(n, id) |> get_node_name

    case GenServer.call(target, :is_active) do
      Active ->
        GenServer.cast(target, {:pushsum, {s, w}})

      ina_xy ->
        GenServer.cast(Master, {:node_inactive, ina_xy})
        new_neighbor = GenServer.call(Master, :handle_node_failure)
        GenServer.cast(self(), {:remove_neighbor, target})
        GenServer.cast(self(), {:add_new_neighbor, new_neighbor})
        GenServer.cast(new_neighbor, {:add_new_neighbor, get_node_name(id)})
    end
  end
end
