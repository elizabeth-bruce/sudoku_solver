require Square

defmodule Board do
  @enforce_keys [:board]

  @default_row_size 9
  @default_column_size 9

  @default_row_partition_size 3
  @default_column_partition_size 3

  defstruct [:board]

  def square_at(board, coord) do
    board.board[coord]
  end

  def row_coords_of(y) do
    Enum.to_list(1..@default_column_size) |>
    Enum.map(&([ row: y, column: &1 ]))
  end

  def column_coords_of(x) do
    Enum.to_list(1..@default_row_size) |>
    Enum.map(&([ row: &1, column: x ]))
  end

  def row_of(board, y) do
    row_coords_of(y) |>
    Enum.map(&(square_at(board, &1)))
  end

  def column_of(board, x) do
    column_coords_of(x) |>
    Enum.map(&(square_at(board, &1)))
  end

  defp column_neighborhood_of(x) do
    start_column = @default_column_partition_size * Integer.floor_div(x - 1, @default_column_partition_size) + 1
    end_column = start_column + @default_column_partition_size - 1

    Enum.to_list(start_column..end_column) |>
    Enum.map(&row_coords_of/1) |>
    Enum.reduce(&(&1 ++ &2))

  end

  defp row_neighborhood_of(y) do
    start_row = @default_row_partition_size * Integer.floor_div(y - 1, @default_row_partition_size) + 1
    end_row = start_row + @default_row_partition_size - 1

    Enum.to_list(start_row..end_row) |>
    Enum.map(&column_coords_of/1) |>
    Enum.reduce(&(&1 ++ &2))
  end

  def neighborhood_coords_of(x, y) do
    MapSet.intersection(
      MapSet.new(column_neighborhood_of(x)),
      MapSet.new(row_neighborhood_of(y))
    ) |> MapSet.to_list
  end

  def neighborhood_of(board, x, y) do
    neighborhood_coords_of(x, y) |> 
    Enum.map(&(square_at(board, &1)))
  end

  defp square_for_unparsed_val(unparsed_val) do
    {val, _} = Integer.parse(unparsed_val)

    case val do
      0 -> %Square{}
      n -> %Square{ actual_number: n, possible_numbers: [n] }
    end
  end

  def import(filename) do
    board_raw = File.read! filename
    rows_raw = String.split(board_raw, "\n")

    initial_board = Enum.with_index(rows_raw, 1) |>
    Enum.flat_map(fn ({row_raw, row_num}) ->
      String.graphemes(row_raw) |>
      Enum.with_index(1) |>
      Enum.map(fn {unparsed_val, column_num} -> { row_num, column_num, unparsed_val } end)
    end) |>
    Enum.reduce(%{}, fn ({ row, column, unparsed_val }, current_map)->
      Map.put(current_map, [ row: row, column: column ], square_for_unparsed_val(unparsed_val))
    end)

    %Board{board: initial_board}
  end

  defmodule Solutions do
    def naive_solution_step(board) do
      new_board = Enum.map(board.board, 
        fn {[row: row, column: column], square } ->
          row_nums = Board.row_of(board, row) |> Enum.map(&(&1.actual_number))
          column_nums = Board.column_of(board, column) |> Enum.map(&(&1.actual_number))
          neighborhood_nums = Board.neighborhood_of(board, row, column) |> Enum.map(&(&1.actual_number))

          impossible_nums = Enum.filter(row_nums ++ column_nums ++ neighborhood_nums, &(&1 != nil)) |> Enum.uniq
          
          {[row: row, column: column], Square.exclude(square, impossible_nums)}
        end
      ) |> Enum.reduce(%{},
        fn ({coord, square}, current_board) -> Map.put(current_board, coord, square) end
      )

      %Board{ board: new_board }
    end
  end
end
