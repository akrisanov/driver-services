## First image builds the application release  -----------------------------------------------------

# Alias this container as builder:
FROM bitwalker/alpine-elixir as builder

# Compile app
RUN mkdir /zombie_driver
WORKDIR /zombie_driver

ENV MIX_ENV=prod

# Install Elixir Deps and compile the app
ADD mix.* ./
RUN mix local.rebar
RUN mix local.hex --force
RUN mix deps.get --only prod

ADD . .
RUN mix compile

WORKDIR /zombie_driver

# Building application via Distillery
RUN mix release --env=prod --verbose

## Second image runs the application release -------------------------------------------------------

FROM alpine:3.8

RUN apk upgrade --no-cache && \
    apk add --no-cache bash openssl

# Exposes this port from the docker container to the host machine
EXPOSE 4000

ENV PORT=4000 \
    MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    SHELL=/bin/bash

WORKDIR /zombie_driver

COPY --from=builder /zombie_driver/_build/prod/rel/zombie_driver/releases/0.1.0/zombie_driver.tar.gz .

RUN tar zxf zombie_driver.tar.gz && rm zombie_driver.tar.gz

RUN chown -R root ./releases
RUN ["chmod", "+x", "./releases/0.1.0/commands/run.sh"]

USER root

CMD ./releases/0.1.0/commands/run.sh
