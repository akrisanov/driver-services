defmodule Gateway.RouterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test

  import Mock

  alias Gateway.Router

  @opts Gateway.Router.init([])
  @location %{"latitude" => 48.864193, "longitude" => "2.350498"}

  test "send a payload to NSQ when a dynamic endpoint has information about its topic" do
    with_mocks([
      {NSQ.Producer.Supervisor, [], [start_link: fn _topic, %NSQ.Config{} -> {:ok, nil} end]},
      {NSQ.Producer, [], [pub: fn _producer, _message -> {:ok, "OK"} end]}
    ]) do
      conn =
        :post
        |> conn("/cab/1/locations", Jason.encode!(@location))
        |> put_req_header("content-type", "application/json")

      conn = Router.call(conn, @opts)

      assert conn.status == 200
      assert conn.resp_body == "Sent to locations"
    end
  end

  test "renders response of Zombie Driver service when an HTTP request is successful" do
    payload = %{id: 1, zombie: true}

    with_mocks([
      {HTTPoison, [],
       [get: fn _ -> {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(payload)}} end]}
    ]) do
      conn = conn(:get, "/cab/1")
      conn = Router.call(conn, @opts)

      assert conn.status == 200
      assert conn.resp_body == Jason.encode!(payload)
    end
  end

  test "renders an error when Zombie Driver service is not reachable or returns an error" do
    with_mocks([
      {HTTPoison, [],
       [get: fn _ -> {:error, %HTTPoison.Error{reason: "Zombies ate our microservice"}} end]}
    ]) do
      conn = conn(:get, "/cab/1")
      conn = Router.call(conn, @opts)

      assert conn.status == 400
      assert conn.resp_body == "Can't determine if driver is zombie or not."
    end
  end

  test "renders :not_found when requesting not defined endpoint" do
    conn = conn(:get, "/not/defined/endpoint")
    conn = Router.call(conn, @opts)

    assert conn.status == 404
    assert conn.resp_body == "Hello, is it me you're looking for?"
  end

  test "renders an error when something unknown happened in the request handler" do
    conn = conn(:delete, "/cab/1")
    conn = Router.call(conn, @opts)

    assert conn.status == 400
    assert conn.resp_body == "This behaviour is not implemented yet :("
  end
end
