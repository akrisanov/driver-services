defmodule Gateway do
  @moduledoc """
  Starts a supervisor that runs the HTTP server for on port 4000.
  """
  use Application

  def start(_type, _args) do
    children = [
      # Use Plug.Cowboy.child_spec/3 to register the router as a plug
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Gateway.Router,
        options: [port: 4000]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
