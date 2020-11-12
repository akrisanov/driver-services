# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :driver_location,
  nsqlookupds: ["127.0.0.1:4161"],
  redis: "redis://127.0.0.1:6379/3"
