# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :zombie_driver,
  redis: "redis://127.0.0.1:6379/3",
  driver_location_host: "localhost:4001"
