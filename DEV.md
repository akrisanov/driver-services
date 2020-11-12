# Development Environment

Sometimes it's more convenient and quicker to just run all services and third-party
dependencies locally. We don't need to build all containers and can start applications
in `:dev` mode.

## Localhost

```bash
$ brew install elixir
$ brew install nsq
$ breq install redis
$ brew service start redis

# start NSQ cluster – each inside separate shell!
$ nsqlookupd
$ nsqd --lookupd-tcp-address=127.0.0.1:4160
$ nsqadmin --lookupd-http-address=127.0.0.1:4161

# test NSQ cluster
$ curl -d 'hello world 1' 'http://127.0.0.1:4151/pub?topic=test'
$ curl -d 'hello world 2' 'http://127.0.0.1:4151/pub?topic=test'
$ curl 'http://127.0.0.1:4151/stats?format=json'
$ curl 'http://127.0.0.1:4161/lookup?topic=test'
$ curl 'http://127.0.0.1:4171/topics/test/'

# run Elixir apps – each inside separate shell!
$ cd gateway && mix deps.get && iex -S mix run           # open https://localhost:4000
$ cd driver-location && mix deps.get && iex -S mix run   # open https://localhost:4001
$ cd zombie-driver && mix deps.get && iex -S mix run     # open https://localhost:4002
```

## Docker

Another option is to build and run all Docker containers:

```bash
$ cd gateway && docker build . -t gateway:0.1.0
$ cd driver-location && docker build . -t driver_location:0.1.0
$ cd zombie-driver && docker build . -t zombie_driver:0.1.0

$ docker-compose up
```

### Connecting to IEX shell

If you need, you always can connect to IEX shell inside running Docker container, e.g.:

```bash
$ docker-compose ps
# pick container from the list
$ docker exec -i -t andrey-technical-test_driver-location_1 /bin/bash
bash-4.4# bin/driver_location remote_console
Erlang/OTP 21 [erts-10.1.1] [source] [64-bit] [smp:6:6] [ds:6:6:10] [async-threads:1] [hipe]

Interactive Elixir (1.7.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(driver_location@127.0.0.1)1> Application.fetch_env!(:driver_location, :nsq_topic)
"locations"
```

## Tailing application logs

```bash
$ docker exec -i -t andrey-technical-test_driver_location_1 /bin/bash
bash-4.4# tail -f log/info.log
bash-4.4# tail -f log/error.log
```

**P.S. Make sure you're not running sevices on the same ports locally.**
