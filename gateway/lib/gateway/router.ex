defmodule Gateway.Router do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  alias Plug.Conn

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
  @nsqds Application.fetch_env!(:gateway, :nsqds)
  @endpoints_file Application.fetch_env!(:gateway, :endpoints_config)

  # Dynamically define routes, no macros required.
  # Fail immediately if something wrong with the config file.
  @endpoints @endpoints_file
             |> YamlElixir.read_from_file!()
             |> Map.fetch!("urls")

  Enum.each(@endpoints, fn endpoint ->
    match endpoint["path"],
      via: endpoint["method"] |> String.downcase() |> String.to_atom(),
      assigns: Map.take(endpoint, Map.keys(endpoint) -- ["path", "method"]) do
      handle_request(conn)
    end
  end)

  # Return 404 for anything else.
  match _ do
    send_resp(conn, 404, "Hello, is it me you're looking for?")
  end

  def init(opts) do
    opts
  end

  # Handle requests of defined endpoints.
  # We can add content-type and other helpful headers to any handler if we need to.

  # Users request this endpoint to know if a driver is a zombie.
  # This endpoint forwards the HTTP request to the Zombie Driver service.
  defp handle_request(%Conn{assigns: %{"http" => %{"host" => host}}} = conn) do
    request_url = host <> conn.request_path

    Logger.info("Sending request to #{request_url}")

    case HTTPoison.get(request_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("Successfully got a response from #{host} service")
        send_resp(conn, 200, body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Can't retrieve #{host} service :( Reason: #{reason}")
        send_resp(conn, 400, "Can't determine if driver is zombie or not.")
    end
  end

  # During a typical day, thousands of drivers send their coordinates every 5 seconds to
  # this endpoint. Coordinates received on this endpoint are converted to NSQ messages listened
  # by the Driver Location service.
  defp handle_request(
         %Conn{
           assigns: %{"nsq" => %{"topic" => nsq_topic}},
           path_params: %{"id" => id},
           body_params: %{"latitude" => lat, "longitude" => lon}
         } = conn
       ) do
    message = Jason.encode!(%{driver_id: id, latitude: lat, longitude: lon})

    producer = nsq_producer_for(nsq_topic)
    NSQ.Producer.pub(producer, message)
    # Always close the connection, but
    # https://github.com/wistia/elixir_nsq/issues/20
    # NSQ.Producer.close/1 doesn't exist
    # Better NSQ client could be a good idea for an open source project. This one is frustrating.

    send_resp(conn, 200, "Sent to #{nsq_topic}")
  end

  defp handle_request(conn) do
    send_resp(conn, 400, "This behaviour is not implemented yet :(")
  end

  # Can be extended for showing exception details, loging the stacktrace, or sending alerts
  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end

  defp nsq_producer_for(topic) do
    {:ok, producer} = NSQ.Producer.Supervisor.start_link(topic, %NSQ.Config{nsqds: @nsqds})
    producer
  end
end
