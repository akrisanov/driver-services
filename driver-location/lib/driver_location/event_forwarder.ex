defmodule DriverLocation.EventForwarder do
  @moduledoc """
  Handles location messages published by the Gateway service and stores them in a Redis database.
  """
  import DriverLocation, only: [execute_redis_command: 1]
  require Logger

  def handle_message(body, msg) do
    Logger.info(
      "Processing NSQ message => id: #{msg.id} | attempts: #{msg.attempts} | timestamp: #{
        msg.timestamp
      }"
    )

    location = Jason.decode!(body)

    with %{"driver_id" => driver_id, "latitude" => lat, "longitude" => lon} <- location do
      # Consumer will retry the message when Redis command fails
      redis_key = "driver:#{driver_id}"
      redis_exp = ["GEOADD", redis_key, lon, lat, DateTime.utc_now() |> DateTime.to_iso8601()]
      execute_redis_command(redis_exp)

      Logger.info("New location #{lon}, #{lat} of driver #{driver_id} has been added to Redis")
      :ok
    else
      # We can decide what to do with wrong messages here. Let's just acknowledge them for now
      # and don't block the queue.
      _ ->
        Logger.error("Malicious message: #{inspect(location)}")
        :ok
    end
  end
end
