defmodule Square do
  @initial_possible_numbers Enum.to_list 1..9
  defstruct actual_number: nil, possible_numbers: @initial_possible_numbers

  defp resolve_actual_number(possible_numbers) do
    case length(possible_numbers) do
      0 -> {:error, "All possible values excluded for square, board error"}
      1 -> {:ok, hd(possible_numbers) }
      _ -> {:ok, nil }
    end 
  end

  defp resolve_actual_number!(possible_numbers) do
    case resolve_actual_number(possible_numbers) do
      {:ok, result } -> result
      {:error, reason } -> raise reason
    end 
  end

  def exclude(square, excluded_numbers) do
    possible_numbers = square.possible_numbers -- excluded_numbers
    
    if square.actual_number do
      square
    else
      %Square{
        possible_numbers: possible_numbers,
        actual_number: resolve_actual_number!(possible_numbers)
      }
    end
  end
end
