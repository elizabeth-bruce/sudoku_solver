require Board
require Square

defmodule Board.Solutions.Parallel do
  def receive_solved_square(current_board, pid_coord_map) do
    receive do
      {square, pid} -> 
      next_board = Map.put(current_board, pid_coord_map[pid], square)
      if map_size(next_board) < 81 do
        receive_solved_square(next_board, pid_coord_map)
      else
        next_board
      end
      _ -> nil
    end
  end
  def solve(board) do
    coord_pid_map = Enum.map(board.board, fn {[row: row, column: column], square} ->
      {:ok, pid} = Board.Solutions.Parallel.SquareProcess.start_link({square, self()})
      {[row: row, column: column], pid}
    end) |> Enum.into(%{})

    pid_coord_map = Enum.map(coord_pid_map, fn {[row: row, column: column], pid} ->
      adjacent_coords =
        Board.row_coords_of(row) ++
        Board.column_coords_of(column) ++
        Board.neighborhood_coords_of(row, column)

      adjacent_uniq_coords = Enum.uniq(adjacent_coords)
      adjacent_pids = Enum.map(adjacent_uniq_coords, fn coord -> coord_pid_map[coord] end)

      Board.Solutions.Parallel.SquareProcess.set_adjacent_pids(pid, adjacent_pids)
      { pid, [row: row, column: column] }
    end) |> Enum.into(%{})

    Enum.each(pid_coord_map, fn {pid, _} -> 
      Board.Solutions.Parallel.SquareProcess.start(pid)
    end)

    completed_board = receive_solved_square(%{}, pid_coord_map)

    %Board{board: completed_board}
  end

  defmodule SquareProcess do
    use GenServer

    defp broadcast_solved_number(square, caller, adjacent_pids) do
      send(caller, {square, self()})
      Enum.map(adjacent_pids, fn pid -> exclude(pid, square.actual_number) end)
    end

    def init({square, caller}) do
      {:ok, {square, caller}}
    end

    def handle_cast({:set_adjacent_pids, adjacent_pids}, {square, caller}) do
      {:noreply, {square, caller, adjacent_pids}}
    end

    def handle_cast({:start}, {square, caller, adjacent_pids}) do
      if square.actual_number do
        broadcast_solved_number(square, caller, adjacent_pids)
      end

     {:noreply, {square, caller, adjacent_pids}}
    end

    def handle_cast({:exclude, number}, {square, caller, adjacent_pids}) do
      new_square = Square.exclude(square, [number])
      case { square.actual_number, new_square.actual_number } do
        { nil, nil } -> nil
        { nil, _ } -> broadcast_solved_number(new_square, caller, adjacent_pids)
        { _, _ } -> nil

      end

      {:noreply, {new_square, caller, adjacent_pids}}
    end

    def start_link({square, caller}) do
      GenServer.start_link(__MODULE__, {square, caller})
    end

    def set_adjacent_pids(pid, adjacent_pids) do
      GenServer.cast(pid, {:set_adjacent_pids, adjacent_pids})
    end

    def exclude(pid, number) do
      GenServer.cast(pid, {:exclude, number})
    end

    def start(pid) do
      GenServer.cast(pid, {:start})
    end
  end
end
