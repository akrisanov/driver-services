defmodule DriverLocation do
  @moduledoc """
  Starts a supervisor that runs the HTTP server for on port 4001.
  """
  use Application

  require Logger

  # Compile-time configs
  @nsqlookupds Application.fetch_env!(:driver_location, :nsqlookupds)
  @nsq_topic Application.fetch_env!(:driver_location, :nsq_topic)
  @redis Application.fetch_env!(:driver_location, :redis)

  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        [
          http_server_spec()
        ]
      else
        [
          http_server_spec(),
          nsq_consumer_spec()
        ]
      end

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def execute_redis_command(expressions) when is_list(expressions) do
    {:ok, con} = Redix.start_link(@redis, name: :driver_location)
    {:ok, result} = Redix.command(con, expressions)
    Redix.stop(con)
    result
  end

  defp http_server_spec() do
    {
      Plug.Cowboy,
      scheme: :http, plug: DriverLocation.Router, options: [port: 4001]
    }
  end

  defp nsq_consumer_spec() do
    %{
      id: NSQ.Consumer.Supervisor,
      start: {
        NSQ.Consumer.Supervisor,
        :start_link,
        [
          @nsq_topic,
          "driver-location",
          %NSQ.Config{
            nsqlookupds: @nsqlookupds,
            message_handler: DriverLocation.EventForwarder
          }
        ]
      }
    }
  end
end
