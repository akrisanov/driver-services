defmodule DriverLocation.RouterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test

  import Fixtures
  import Mock

  alias DriverLocation.Router

  @opts Router.init([])

  describe "[GET] /drivers/:id/locations" do
    test "renders locations sorted by updated_at field" do
      with_mocks(default_mocks(redis_fixture())) do
        conn = conn(:get, "drivers/1/locations")
        conn = Router.call(conn, @opts)
        resp = Jason.decode!(conn.resp_body)

        assert conn.status == 200
        assert Enum.map(resp, &Map.get(&1, "updated_at")) == sorted_timestamps_fixture()
      end
    end

    test "renders locations sorted by updated_at field and filtered by hours" do
      all_fixtures =
        Enum.concat(
          redis_fixture(),
          redis_fixture_last_hour()
        )

      with_mocks(default_mocks(all_fixtures)) do
        conn = conn(:get, "drivers/1/locations?hours=1")
        conn = Router.call(conn, @opts)
        resp = Jason.decode!(conn.resp_body)

        assert conn.status == 200
        assert length(resp) == 1

        assert Enum.map(resp, &Map.take(&1, ["latitude", "longitude"])) == [
                 %{
                   "latitude" => 8.864192376732937,
                   "longitude" => 3.350500166416168
                 }
               ]
      end
    end

    test "renders locations sorted by updated_at field and filtered by minutes" do
      all_fixtures =
        Enum.concat(
          redis_fixture(),
          redis_fixture_last_five_minutes()
        )

      with_mocks(default_mocks(all_fixtures)) do
        conn = conn(:get, "drivers/1/locations?minutes=5")
        conn = Router.call(conn, @opts)
        resp = Jason.decode!(conn.resp_body)

        assert conn.status == 200
        assert length(resp) == 2

        assert Enum.map(resp, &Map.take(&1, ["latitude", "longitude"])) == [
                 %{
                   "latitude" => 8.864192376732937,
                   "longitude" => 3.350500166416168
                 },
                 %{
                   "latitude" => 48.86419237673294,
                   "longitude" => 2.350500166416168
                 }
               ]
      end
    end

    test "renders locations sorted by updated_at field and filtered by seconds" do
      all_fixtures =
        Enum.concat(
          redis_fixture(),
          redis_fixture_last_seconds()
        )

      with_mocks(default_mocks(all_fixtures)) do
        conn = conn(:get, "drivers/1/locations?seconds=30")
        conn = Router.call(conn, @opts)
        resp = Jason.decode!(conn.resp_body)

        assert conn.status == 200
        assert length(resp) == 1

        assert Enum.map(resp, &Map.take(&1, ["latitude", "longitude"])) == [
                 %{
                   "latitude" => 48.86419237673294,
                   "longitude" => 2.350500166416168
                 }
               ]
      end
    end
  end

  test "renders :not_found when requesting not defined endpoint" do
    with_mocks(default_mocks([])) do
      conn = conn(:get, "/not/defined/endpoint")
      conn = Router.call(conn, @opts)

      assert conn.status == 404
      assert conn.resp_body == "Hello, is it me you're looking for?"
    end
  end

  defp default_mocks(fixture) do
    [
      {Redix, [], [start_link: fn _con, _name -> {:ok, nil} end]},
      {Redix, [], [stop: fn _con -> {:ok, nil} end]},
      {Redix, [], [command: fn _con, _exp -> {:ok, fixture} end]}
    ]
  end
end
