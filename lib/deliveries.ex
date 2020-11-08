defmodule Barbora.Deliveries do
  def filter_available_deliveries(%{"deliveries" => [%{"params" => %{"matrix" => matrix}}]}) do
    Enum.flat_map(matrix, fn day -> filter_available_hours(day) end)
  end

  defp filter_available_hours(%{"hours" => hours, "id" => day_id}) do
    Enum.filter(hours, fn
      %{"available" => true} -> true
      _ -> false
    end)
    |> add_day_id(day_id)
  end

  defp add_day_id(hours, day_id) do
    Enum.map(hours, &Map.put_new(&1, "day_id", day_id))
  end

  def filter_fast_deliveries(%{"deliveries" => [%{"params" => %{"matrix" => matrix}}]}, fast_days) do
    Enum.flat_map(matrix, fn day -> filter_fast_available_days(day, fast_days) end)
  end

  defp filter_fast_available_days(%{"hours" => hours, "id" => day_id}, fast_days) do
    Enum.filter(hours, fn _ -> days_filter(fast_days, day_id) end)
    |> Enum.filter(fn hour -> availability_filter(hour) end)
    |> add_day_id(day_id)
  end

  defp days_filter(days_allowed, day_id) do
     Enum.any?(days_allowed, fn d -> d == day_id end)
  end

  defp availability_filter(%{"available" => available}) do
    available
  end

end
