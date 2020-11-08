defmodule Barbora.DeliveriesTest do
  use ExUnit.Case

  @empty_deliveries ResourcesHelper.get_resource("empty_deliveries.json")
  @few_deliveries ResourcesHelper.get_resource("few_deliveries.json")
  @late_deliveries ResourcesHelper.get_resource("late_deliveries.json")

  test "filters empty deliveries" do
    assert Barbora.Deliveries.filter_available_deliveries(@empty_deliveries) == []
  end

  test "filters few deliveries" do
    assert Barbora.Deliveries.filter_available_deliveries(@few_deliveries) |> Enum.count() == 2
  end

  test "filter late deliveries" do
    #fast_days = [ "2020-11-09", "2020-11-10" ]
    dt_from = ~D[2020-11-08]
    dt_range = Date.range(dt_from, dt_from |> Date.add(2))
    fast_days = Enum.map(dt_range, fn x -> Date.to_iso8601(x) end)
    assert Barbora.Deliveries.filter_fast_deliveries(@late_deliveries, fast_days) == []
  end

  test "deliveries has deliveryTime key" do
    for delivery <- Barbora.Deliveries.filter_available_deliveries(@few_deliveries) do
      assert %{"deliveryTime" => _deliveryTime} = delivery
    end
  end
end
