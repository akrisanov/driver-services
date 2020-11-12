# Notes

Each microservice has a README file containing useful information about
the development environment and the implementation:

- [gateway](gateway/README.md)
- [driver-location](driver-location/README.md)
- [zombie-driver](zombie-driver/README.md)

Also, there are some helpful comments in the code. Maybe they can be a topic for future improvements.

Before pushing any commits to this repo I do:

- Running the tests on my laptop and make sure they are all green
- [Running the services locally and manually test all endpoints](DEV.md)
- Starting the containers `docker-compose up -d` and manually test all endpoints – last sanity check

## The Caveats

- All microservices run under HTTP connection and it would be nice to switch to HTTPS.
  Even microservices inside private VPC subnets shouldn't expose unencrypted endpoints.
  Let's assume for now that we keep that in mind and will take care about DevOps issues a bit later.
- I use `elixir_nsq` library as NSQ client that communicates with a queue via TCP and it's a bit odd.
  But it seems to be the best option for now in Elixir.

## Running Tests

- On majority of projects I use Circle CI with [following configs](https://gist.github.com/akrisanov/4be26074ec0b900c1d9f938a76ced3f7).
  It runs linters, security cheks, tests, and also pushes test coverage results to coveralls.io.
- I put `mix test` command in Makefile and assume that you have installed Elixir on CI instance.

## Testing Endpoints / Manual Testing

```bash
## Send locations to Gateway server
curl -X "PATCH" "http://localhost:4000/drivers/1/locations" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "longitude": "3.350498",
  "latitude": "58.864193"
}'

## Request information about driver's locations
curl "http://localhost:4001/drivers/1/locations"
curl "http://localhost:4001/drivers/1/locations?hours=1"
curl "http://localhost:4001/drivers/1/locations?minutes=1"
curl "http://localhost:4001/drivers/1/locations?seconds=10"

## Request information about driver
## Forwards the HTTP request to the Zombie Driver service
curl "http://localhost:4000/drivers/1" # => true

## Send locations to Gateway server
curl -X "PATCH" "http://localhost:4000/drivers/1/locations" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "longitude": "2.350498",
  "latitude": "48.864193"
}'

## Request information about driver
## Forwards the HTTP request to the Zombie Driver service
curl "http://localhost:4000/drivers/1" # => false
```
