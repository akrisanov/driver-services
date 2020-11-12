# ZombieDriver

The Zombie Driver service is a microservice that determines if a driver is a zombie or not.

**A driver is a zombie if he has driven less than 500 meters in the last 5 minutes.**

## Predicate

Given that this is the first time we do such a partnership, our operational team mentioned that
they might need to change the predicate values (duration and distance) through the duration of
the partnership. That would allow them to increase the chances of having passengers encounter
zombie drivers. For example, on the second day they might decide that a zombie is a driver tha
hasn't moved more than 2km over the last 30 minutes.

## Configuring the predicate

It's possible to specify duration and distance values in application config:

```elixir
config :zombie_driver,
  duration_value: 5,
  # Allowed values: hours, minutes, seconds
  duration_unit: "minutes",
  distance_value: 500,
  # Allowed values: `m` for meters, `km` for kilometers, `mi` for miles, `ft` for feet
  distance_unit: "m"
```

[Internal Endpoint](API.md)

## Notes

When a request hits the `Zombie Driver` endpoint the microservice does:

1. Ask `Driver Location` for recent locations of a particular driver.
2. Executes Redis [GEODIST](https://redis.io/commands/geodist) command for calculating a distance
   between all location points in required units.
3. Checks if driver either zombie or not by using the resulting distance.
4. Renders the JSON payload.

## Dependencies

- Elixir >= 1.7
- Redis
- Driver Location Service

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
docker build . -t zombie_driver:0.1.0
```

Running Docker container localy:

```bash
docker run --rm -ti \
           -p 4002:4002 \
           -e REPLACE_OS_VARS=true \
           zombie_driver:0.1.0
```

P.S. You can build OTP release without Docker if you wish.

```bash
MIX_ENV=prod mix release
...
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/prod/rel/zombie_driver/bin/zombie_driver console

    # start in the foreground, like 'mix run --no-halt'
    > _build/prod/rel/zombie_driver/bin/zombie_driver foreground

...

For a complete listing of commands and their use:

    > _build/prod/rel/zombie_driver/bin/zombie_driver help
```

## Copyright

Copyright (C) 2018 Andrey Krisanov. The app is licensed and distributed under the MIT license :)
