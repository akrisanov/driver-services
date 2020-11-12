# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :gateway,
  endpoints_config: "config.dev.yaml",
  nsqds: ["127.0.0.1:4150"]
