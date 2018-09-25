defmodule GossipSim do
  @moduledoc """
  Documentation for GossipSim.
  """
  use GenServer

  @doc """
  Hello world.

  ## Examples

      iex> GossipSim.hello()
      :world

  """
  def hello do
    :world
  end

  def main(args) when Kernel.length(args) != 3 do
    raise ArgumentError, message: "Insfficient/Excess Arguments. Enter N and k"
  end

  def main(args) do
    numNodes = String.to_integer(Enum.at(args, 0))
    topology = Enum.at(args, 1)
    algorithm = Enum.at(args, 2)

    percentage =
      if Kernel.length(args) == 4 do
        Enum.at(args, 3)
      else
        0
      end

    driver(numNodes, topology, algorithm, percentage)
  end

  defp driver(numNodes, topology, algorithm, percentage) do
    size = round(Float.ceil(:math.sqrt(numNodes)))
    GossipSim.observer(size)

    case topology do
      "line" ->
        Line.create(numNodes, algorithm)
        # deactivate(percentage)
        GenServer.cast(Line.get_node_name(round(1)), {:gossip, :_sending})

        # "grid" ->
        #   Grid.create_network(size, false, 0)
        #   deactivate(percentage)

        #   GenServer.cast(
        #     Grid.node_name(round(size / 2), round(size / 2)),
        #     {:message_gossip, :_sending}
        #   )

        # "i_grid" ->
        #   Grid.create_network(size, true, 0)
        #   deactivate(percentage)

        #   GenServer.cast(
        #     Grid.node_name(round(size / 2), round(size / 2)),
        #     {:message_gossip, :_sending}
        #   )

        # "full" ->
        #   Full.create_network(numNodes, 0)
        #   deactivate(percentage)
        #   GenServer.cast(Full.node_name(round(numNodes / 2)), {:message_gossip, :_sending})
    end

    Process.sleep(:infinity)
  end

  def observer(size) do
    GenServer.start_link(GossipSim, size, name: Master)
  end

  def init(size) do
    # [cast_number, nodes_recieved, nodes_hibernated, prev_node, prev_to_prev_node, recieve_count, hibernation_count]
    {:ok, [1, [], [], [{1, 1}], [{1, 1}], 0, 0, size, 1, 0, [], []]}
  end

  def handle_cast({:received, node}, [
        cast_num,
        received,
        hibernated,
        prev_node,
        prev_node_2,
        r_count,
        h_count,
        size,
        draw_every,
        init_time,
        _nodes,
        dead_nodes
      ]) do
    init_time_ =
      if cast_num == 1 do
        DateTime.utc_now()
      else
        init_time
      end

    draw_every_ =
      if cast_num == draw_every * 10 do
        draw_every * 5
      else
        draw_every
      end

    case rem(cast_num, draw_every) == 0 do
      true ->
        Task.start(GossipSim, :draw_image, [
          received,
          hibernated,
          0,
          node,
          prev_node,
          prev_node_2,
          size,
          cast_num,
          dead_nodes
        ])

      false ->
        ""
    end

    {:noreply,
     [
       cast_num + 1,
       received ++ node,
       hibernated,
       node,
       prev_node,
       r_count + 1,
       h_count,
       size,
       draw_every_,
       init_time_,
       _nodes,
       dead_nodes
     ]}
  end

  def handle_cast({:node_inactive, node}, [
        _cast_num,
        _received,
        _hibernated,
        _prev_node,
        _prev_node_2,
        _r_count,
        _h_count,
        _size,
        _draw_every,
        _init_time,
        nodes,
        dead_nodes
      ]) do
    {:noreply,
     [
       _cast_num,
       _received,
       _hibernated,
       _prev_node,
       _prev_node_2,
       _r_count,
       _h_count,
       _size,
       _draw_every,
       _init_time,
       List.delete(nodes, node),
       dead_nodes ++ node
     ]}
  end

  def handle_call(:handle_node_failure, {pid, _}, [
        _cast_num,
        _received,
        _hibernated,
        _prev_node,
        _prev_node_2,
        _r_count,
        _h_count,
        _size,
        _draw_every,
        _init_time,
        nodes,
        dead_nodes
      ]) do
    # IO.puts("inspecting #{inspect _from}")
    new_node = Enum.random(nodes)

    case :erlang.whereis(new_node) do
      ^pid -> new_node = List.delete(nodes, new_node) |> Enum.random()
      _ -> ""
    end

    {:reply, new_node,
     [
       _cast_num,
       _received,
       _hibernated,
       _prev_node,
       _prev_node_2,
       _r_count,
       _h_count,
       _size,
       _draw_every,
       _init_time,
       nodes,
       dead_nodes
     ]}
  end

  def handle_cast({:hibernated, node}, [
        cast_num,
        received,
        hibernated,
        prev_node,
        prev_node_2,
        r_count,
        h_count,
        size,
        draw_every,
        init_time,
        nodes,
        dead_nodes
      ]) do
    draw_image(received, hibernated, 1, node, prev_node, prev_node_2, size, cast_num, dead_nodes)
    end_time = DateTime.utc_now()
    convergence_time = DateTime.diff(end_time, init_time, :millisecond)
    IO.puts("Convergence time: #{convergence_time} ms")

    draw_image(
      received,
      hibernated,
      1,
      node,
      prev_node,
      prev_node_2,
      size,
      cast_num,
      dead_nodes
    )

    {:noreply,
     [
       cast_num + 1,
       received,
       hibernated ++ node,
       node,
       prev_node,
       r_count,
       h_count + 1,
       size,
       draw_every,
       init_time,
       nodes,
       dead_nodes
     ]}
  end

  def draw_image(
        received,
        hibernated,
        terminated,
        node,
        prev_node,
        prev_node_2,
        size,
        cast_num,
        dead_nodes
      ) do
    image = :egd.create(8 * (size + 1), 8 * (size + 1))
    fill1 = :egd.color({250, 70, 22})
    fill2 = :egd.color({0, 33, 164})
    fill3 = :egd.color({255, 0, 0})
    fill4 = :egd.color({0, 0, 0})

    Enum.each(received, fn {first, second} ->
      :egd.rectangle(image, {first * 8 - 2, second * 8 - 2}, {first * 8, second * 8}, fill1)
    end)

    [{first, second}] = prev_node_2
    :egd.filledEllipse(image, {first * 8 - 2, second * 8 - 2}, {first * 8, second * 8}, fill2)
    [{first, second}] = prev_node

    :egd.filledEllipse(
      image,
      {first * 8 - 3, second * 8 - 3},
      {first * 8 + 1, second * 8 + 1},
      fill2
    )

    case terminated do
      0 ->
        [{first, second}] = node

        :egd.filledEllipse(
          image,
          {first * 8 - 4, second * 8 - 4},
          {first * 8 + 2, second * 8 + 2},
          fill2
        )

      1 ->
        [{first, second}] = node

        :egd.filledEllipse(
          image,
          {first * 8 - 6, second * 8 - 6},
          {first * 8 + 4, second * 8 + 4},
          fill3
        )
    end

    Enum.each(dead_nodes, fn {first, second} ->
      :egd.filledRectangle(
        image,
        {first * 8 - 3, second * 8 - 3},
        {first * 8 + 1, second * 8 + 1},
        fill4
      )
    end)

    rendered_image = :egd.render(image)
    File.write("live.png", rendered_image)
    File.write("~/SS/snap#{cast_num}.png", rendered_image)
  end
end
