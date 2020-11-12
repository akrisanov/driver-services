defmodule ZombieDriver.RouterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test

  import Fixtures
  import Mock

  alias ZombieDriver.Router

  @opts Router.init([])

  describe "[GET] /drivers/:id" do
    test "driver is a zombie when we can't retrieve his/her locations" do
      {conn, resp} = http_request()
      assert conn.status == 200
      assert resp["zombie"]
    end
  end

  describe "is_driver_zombie?" do
    test "true when a driver doesn't have a ride" do
      with_mocks([
        driver_locations_mock(empty_driver_locations_fixture())
      ]) do
        {conn, resp} = http_request()

        assert conn.status == 200
        assert resp["zombie"]
      end
    end

    test "true when a driver has driven < required distance during required period" do
      with_mocks(
        Enum.concat(
          redis_mocks("100.00"),
          [driver_locations_mock(driver_locations_fixture())]
        )
      ) do
        {conn, resp} = http_request()

        assert conn.status == 200
        assert resp["zombie"]
      end
    end

    test "false when a driver has driven >= required distance during required period" do
      with_mocks(
        Enum.concat(
          redis_mocks("250.00"),
          [driver_locations_mock(driver_locations_fixture())]
        )
      ) do
        {conn, resp} = http_request()

        assert conn.status == 200
        refute resp["zombie"]
      end
    end
  end

  defp http_request() do
    conn = conn(:get, "drivers/1")
    conn = Router.call(conn, @opts)
    {conn, Jason.decode!(conn.resp_body)}
  end

  defp driver_locations_mock(fixture) do
    {HTTPoison, [],
     [
       get: fn _ ->
         {:ok,
          %HTTPoison.Response{
            status_code: 200,
            body: Jason.encode!(fixture)
          }}
       end
     ]}
  end

  defp redis_mocks(fixture) do
    [
      {Redix, [], [start_link: fn _con, _name -> {:ok, nil} end]},
      {Redix, [], [stop: fn _con -> {:ok, nil} end]},
      {Redix, [], [command: fn _con, _exp -> {:ok, fixture} end]}
    ]
  end
end
