defmodule Fixtures do
  @moduledoc false

  def empty_driver_locations_fixture() do
    []
  end

  def driver_locations_fixture() do
    [
      %{
        latitude: "48.86419237673293736",
        longitude: "2.35050016641616821",
        updated_at: DateTime.utc_now() |> Timex.shift(minutes: -3)
      },
      %{
        latitude: "58.86419237673293736",
        longitude: "3.35050016641616821",
        updated_at: DateTime.utc_now() |> Timex.shift(minutes: -2)
      }
    ]
  end
end
