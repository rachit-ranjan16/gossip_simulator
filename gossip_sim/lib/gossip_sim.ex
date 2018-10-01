defmodule GossipSim do
  @moduledoc """
  Documentation for GossipSim.
  """
  use GenServer

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

        case algorithm do
          "gossip" -> GenServer.cast(Line.get_node_name(1), {:gossip, :_sending})
          "pushsum" -> GenServer.cast(Line.get_node_name(1), {:pushsum, {1, 1}})
        end

      "imperfect_line" ->
        ImperfectLine.create(numNodes, algorithm)

        case algorithm do
          "gossip" -> GenServer.cast(ImperfectLine.get_node_name(1), {:gossip, :_sending})
          "pushsum" -> GenServer.cast(ImperfectLine.get_node_name(1), {:pushsum, {1, 1}})
        end

      "fully_connected" ->
        FullyConnected.create(numNodes, algorithm)

        case algorithm do
          "gossip" -> GenServer.cast(FullyConnected.get_node_name(1), {:gossip, :_sending})
          "pushsum" -> GenServer.cast(FullyConnected.get_node_name(1), {:pushsum, {1, 1}})
        end

      "grid3d" ->
        size = round(Float.ceil(:math.pow(numNodes, 1 / 3)))
        Grid3D.create(size - 1, algorithm)

        case algorithm do
          "gossip" -> GenServer.cast(Grid3D.get_node_name(0, 0, 0), {:gossip, :_sending})
          "pushsum" -> GenServer.cast(Grid3D.get_node_name(0, 0, 0), {:pushsum, {1, 1}})
        end

      "random2d" ->
        nodes = Random2D.create(numNodes, algorithm)

        case algorithm do
          "gossip" ->
            GenServer.cast(
              Random2D.get_node_name(
                elem(Enum.at(nodes, 0), 0),
                elem(Enum.at(nodes, 0), 1)
              ),
              {:gossip, :_sending}
            )

          "pushsum" ->
            GenServer.cast(
              Random2D.get_node_name(
                elem(Enum.at(nodes, 0), 0),
                elem(Enum.at(nodes, 0), 1)
              ),
              {:pushsum, {1, 1}}
            )
        end

      "torus" ->
        size = round(Float.ceil(:math.pow(numNodes, 1 / 3)))
        Torus.create(size - 1, algorithm)

        case algorithm do
          "gossip" -> GenServer.cast(Torus.get_node_name(0, 0, 0), {:gossip, :_sending})
          "pushsum" -> GenServer.cast(Torus.get_node_name(0, 0, 0), {:pushsum, {1, 1}})
        end
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
    end_time = DateTime.utc_now()
    convergence_time = DateTime.diff(end_time, init_time, :millisecond)
    IO.puts("Convergence Time = #{convergence_time} ms")

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
end
