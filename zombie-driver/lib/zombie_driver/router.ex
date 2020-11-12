defmodule ZombieDriver.Router do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  require Logger
  plug Plug.Logger

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug :match
  plug :dispatch

  # Compile-time configs
  @duration_value Application.fetch_env!(:zombie_driver, :duration_value)
  @duration_unit Application.fetch_env!(:zombie_driver, :duration_unit)
  @distance_value Application.fetch_env!(:zombie_driver, :distance_value)
  @distance_unit Application.fetch_env!(:zombie_driver, :distance_unit)

  @redis Application.fetch_env!(:zombie_driver, :redis)
  @driver_location_host Application.fetch_env!(:zombie_driver, :driver_location_host)

  get "/drivers/:id" do
    payload = %{
      id: String.to_integer(id),
      zombie: is_driver_zombie?(id)
    }

    send_resp(conn, 200, Jason.encode!(payload))
  end

  # Return 404 for anything else.
  match _ do
    send_resp(conn, 404, "Hello, is it me you're looking for?")
  end

  def init(opts) do
    opts
  end

  def is_driver_zombie?(driver_id) when is_binary(driver_id) do
    locations = fetch_locations_for(driver_id)

    case locations do
      [] ->
        # Driver is a zombie when we can't retrieve its locations. Don't take a risk.
        true

      _ ->
        redis_key = "driver:#{driver_id}"
        member_key = "updated_at"

        redis_members =
          locations
          |> Enum.map(&Map.get(&1, member_key))

        distance = calculate_distance(redis_key, redis_members)
        distance < @distance_value
    end
  end

  defp fetch_locations_for(driver_id) when is_binary(driver_id) do
    request_url =
      "#{@driver_location_host}/drivers/#{driver_id}/locations?#{@duration_unit}=#{@duration_value}"

    Logger.info("Sending request to #{@driver_location_host} service")

    case HTTPoison.get(request_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("Successfully got a response from #{@driver_location_host} service")
        Jason.decode!(body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Can't retrieve #{@driver_location_host} service :( Reason: #{reason}")
        []
    end
  end

  defp calculate_distance(redis_key, redis_members) do
    {:ok, con} = Redix.start_link(@redis, name: :driver_location)

    routes =
      redis_members
      |> Enum.chunk_every(2, 1, [List.last(redis_members)])

    total_distance =
      routes
      |> Enum.map(&query_redis(&1, con, redis_key))
      |> Enum.sum()

    Redix.stop(con)

    total_distance
  end

  defp query_redis([start, finish], redis_con, redis_key) do
    command = ["GEODIST", redis_key, start, finish, @distance_unit]

    {:ok, result} = Redix.command(redis_con, command)

    case result do
      nil ->
        raise "Geoindexes are not found"

      _ ->
        String.to_float(result)
    end
  end

  # Can be extended for showing exception details, loging the stacktrace, or sending alerts
  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
