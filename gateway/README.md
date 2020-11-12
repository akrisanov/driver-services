# Gateway Service

The `Gateway` service is a _public facing service_.
HTTP requests hitting this service are either transformed into [NSQ](https://github.com/nsqio/nsq)
messages or forwarded via HTTP to specific services.

The service are configurable dynamically by loading the provided `config.yaml` file to register
endpoints during its initialization.

[Public Endpoints](API.md)

## Notes

- The `Gateway` service looks for me exactly as API Gateway pattern in microservice architecture.
  In theory, it can do a lot of stuff like authentication, TLS termination, rate limiting,
  distributed tracing and so on. But let's keep it simple for now ;)
- Having `config.yaml` for configuring the application is not idiomatic Elixir way.
  But I assume you embrace that pattern for all your microservices and it's handy for DevOps stuff
  like Mesosphere DC/OS or Kubernetes-native tools. And yes, such files could be really verbose.

## Dependencies

- Elixir >= 1.7
- NSQ
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
2. Second image runs the OTP release of the Gateway service.

Building Docker container:

```bash
docker build . -t gateway:0.1.0
```

Running Docker container localy:

```bash
docker run --rm -ti \
           -p 4000:4000 \
           -e REPLACE_OS_VARS=true \
           gateway:0.1.0
```

P.S. You can build OTP release without Docker if you wish.

```bash
MIX_ENV=prod mix release
...
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/prod/rel/gateway/bin/gateway console

    # start in the foreground, like 'mix run --no-halt'
    > _build/prod/rel/gateway/bin/gateway foreground

...

For a complete listing of commands and their use:

    > _build/prod/rel/gateway/bin/gateway help
```

## Copyright

Copyright (C) 2018 Andrey Krisanov. The app is licensed and distributed under the MIT license :)
