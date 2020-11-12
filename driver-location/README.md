# Driver Location Service

The Driver Location service is a microservice that consumes drivers' location messages published by
the Gateway service and stores them in a Redis database.

It also provides an internal endpoint that allows other services to retrieve the drivers' locations,
filtered and sorted by their addition date

[Internal Endpoint](API.md)

## Notes

The tricky part of this microservice is filtering and sorting drivers' locations.
The task's prerequisite is using Redis for that. Well, ok :)

Also, the `zombie-driver` service has something in common with `driver-location`:

> A driver is a zombie if he has driven less than 500 meters in the last 5 minutes.

_That means we could use `driver-location` for fetching locations from storage inside
the last 5 minutes time frame._

My solution is pretty straightforward and based on Redis Geo data structures and commands:

- I put locations into the storage using [GEOADD](https://redis.io/commands/geoadd) associated with
  `driver:#{id}` key. The addition date is an item member.
- Because data is stored into the `driver:#{id}` key as a sorted set, it will be possible to later
  retrieve locations and calculate the driven distance using [GEODIST](https://redis.io/commands/geodist)
  between all locations in requested timeframe.
- Our bottleneck: `/drivers/:id/locations` endpoint fetching driver's location by executing
  [GEORADIUS](https://redis.io/commands/georadius) with `0`, `0` coordinates and really big radius.
  Time complexity: `O(N+log(M))`. Not a worst case, but what if we have millions of records?
  I apply this dummy approach because Redis doesn't support queries by geo member
  (our timestamp / addition datetime) and we have to either implement some application logic as I did,
  or think about other options.

### Thoughts about `/drivers/:id/locations` bottleneck

#### Option 1: PostgreSQL + Redis

`driver-location` service doesn't use Redis at all:

1. Persist locations data into PostgreSQL
2. Retrieve locations from PostgreSQL with a particular filter, e.g. `?minutes=5`
3. `zombie-driver` requests locations of last 5 minutes from our endpoint
   -> gets filtered and sorted by addition date results
   -> adds the results into _Redis_ by `GEOADD` - it's much smaller subset now!
   -> calculates the distance between members of sorted set of locations
   -> does own stuff and returns payload 🏁

#### Option 2: Custom data structure on top of Redis

When we work with geoindexes in Redis we use `zset` type (sorted set) under the hood.
Theoretically, we could build some tree-based data structure with `zset` and usual `keys`
(representing timestamps or their parts). Also, Redis has `ZRANGE` command that selects members from
a sorted set, therefore we don't need to use `GEORADIUS` for this approach. All members are sorted
by location coordinates, not a member name.

Redis is heavily involved in this approach.
That means we can mess up with database commands and it's not easy to test.

--------

Personally, I like more PostgreSQL + Redis option, because it scalable and if need to store more
data about driver's locations, we always can extend PostgreSQL table, do whatever we want
by sorting, filtering, grouping data and use Redis only for geoindexes. Endpoint testing looks
straightforward as well here. We even can think about ditching Redis for PostGIS, I believe.

## Dependencies

- Elixir >= 1.7
- Redis

## Development

```bash
mix deps.get
iex -S mix run
```

## Programming in Style

- Use [EditorConfig](https://editorconfig.org/) with your favourite editor.
- Run `mix format` before pushing your changes.
- Think about code consistency and try [Credo](https://github.com/rrrene/credo).
  Ignore some warning if you have to by using [config comments](https://github.com/rrrene/credo#inline-configuration-via-config-comments).
  You can find all checking rules [here](https://github.com/rrrene/credo/tree/master/lib/credo/check).

You can run all linters in one goal by executing `./rel/commands/lint`

## Testing

- Run `mix test`
- You can check test coverage via [ExCoveralls](https://github.com/parroty/excoveralls):
  `MIX_ENV=test mix coveralls.html`

## Deployment

This service can be deployed to any container service, e.g. AWS ECS or Elastic Beanstalk.

The Docker pipeline is organized in two-steps way:

1. [Distillery](https://hexdocs.pm/distillery/) bakes OTP release inside first Docker image.
2. Second image runs the OTP release of the Driver Location service.

Building Docker container:

```bash
docker build . -t driver_location:0.1.0
```

Running Docker container localy:

```bash
docker run --rm -ti \
           -p 4001:4001 \
           -e REPLACE_OS_VARS=true \
           driver_location:0.1.0
```

P.S. You can build OTP release without Docker if you wish.

```bash
MIX_ENV=prod mix release
...
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/prod/rel/driver_location/bin/driver_location console

    # start in the foreground, like 'mix run --no-halt'
    > _build/prod/rel/driver_location/bin/driver_location foreground

...

For a complete listing of commands and their use:

    > _build/prod/rel/driver_location/bin/driver_location help
```

## Copyright

Copyright (C) 2018 Andrey Krisanov. The app is licensed and distributed under the MIT license :)
