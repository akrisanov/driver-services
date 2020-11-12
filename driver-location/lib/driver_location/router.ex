defmodule DriverLocation.Router do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  import DriverLocation, only: [execute_redis_command: 1]

  plug Plug.Logger

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug :match
  plug :dispatch

  get "/drivers/:id/locations" do
    redis_key = "driver:#{id}"

    # Fetch all saved coordinates (using any big/city radius) of selected driver and return recent ones.
    # Definitely this place is a bottleneck when we have a lot of data: O(N+log(M)).
    # Potentially we could use the city centre coordinates and city radious here.
    redis_exp = ["GEORADIUS", redis_key, 0, 0, 20_000, "km", "WITHCOORD"]

    locations =
      redis_exp
      |> execute_redis_command()
      |> cast_redis_payload()
      |> Enum.filter(&recent_locations(Map.get(&1, :updated_at), conn.query_params))
      |> Enum.sort_by(&timestamp_tuple/1)

    send_resp(conn, 200, Jason.encode!(locations))
  end

  # Return 404 for anything else.
  match _ do
    send_resp(conn, 404, "Hello, is it me you're looking for?")
  end

  def init(opts) do
    opts
  end

  defp recent_locations(timestamp, %{"hours" => hours}) do
    DateTime.diff(DateTime.utc_now(), timestamp) <= 60 * 60 * String.to_integer(hours)
  end

  defp recent_locations(timestamp, %{"minutes" => minutes}) do
    DateTime.diff(DateTime.utc_now(), timestamp) <= 60 * String.to_integer(minutes)
  end

  defp recent_locations(timestamp, %{"seconds" => seconds}) do
    DateTime.diff(DateTime.utc_now(), timestamp) <= String.to_integer(seconds)
  end

  # Return all locations when no filter provided
  defp recent_locations(_timestamp, _) do
    true
  end

  # Can be extended for showing exception details, loging the stacktrace, or sending alerts
  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end

  defp timestamp_tuple(location) when is_map(location) do
    dt = Map.get(location, :updated_at)
    {dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second}
  end

  defp cast_redis_payload(raw_data) when is_list(raw_data) do
    Enum.map(raw_data, fn [timestamp | [[longitude | [latitude | _]] | _]] ->
      %{
        latitude: String.to_float(latitude),
        longitude: String.to_float(longitude),
        updated_at: Timex.parse!(timestamp, "{ISO:Extended}")
      }
    end)
  end
end
