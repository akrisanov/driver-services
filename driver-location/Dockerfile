## First image builds the application release  -----------------------------------------------------

# Alias this container as builder:
FROM bitwalker/alpine-elixir as builder

# Compile app
RUN mkdir /driver_location
WORKDIR /driver_location

ENV MIX_ENV=prod

# Install Elixir Deps and compile the app
ADD mix.* ./
RUN mix local.rebar
RUN mix local.hex --force
RUN mix deps.get --only prod

ADD . .
RUN mix compile

WORKDIR /driver_location

# Building application via Distillery
RUN mix release --env=prod --verbose

## Second image runs the application release -------------------------------------------------------

FROM alpine:3.8

RUN apk upgrade --no-cache && \
    apk add --no-cache bash openssl

# Exposes this port from the docker container to the host machine
EXPOSE 4001

ENV PORT=4001 \
    MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    SHELL=/bin/bash

WORKDIR /driver_location

COPY --from=builder /driver_location/_build/prod/rel/driver_location/releases/0.1.0/driver_location.tar.gz .

RUN tar zxf driver_location.tar.gz && rm driver_location.tar.gz

RUN chown -R root ./releases
RUN ["chmod", "+x", "./releases/0.1.0/commands/run.sh"]

USER root

CMD ./releases/0.1.0/commands/run.sh
