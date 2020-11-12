# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

config :gateway,
  endpoints_config: "config.yaml",
  nsqds: ["nsqd:4150"]

# and access this configuration in your application as:
#
#     Application.get_env(:gateway, :key)
#
# You can also configure a 3rd-party app:

config :logger,
  backends: [{LoggerFileBackend, :info}, {LoggerFileBackend, :error}]

# All the logs that are less or equal to the verbosity will be logged regardless of the backend.
# Verbosity levels: debug > info > warn > error.
config :logger, :info,
  path: "log/info.log",
  level: :info

config :logger, :error,
  path: "log/error.log",
  level: :error

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

config_file_path = "#{Mix.env()}.exs"

if File.exists?(Path.expand("config/#{config_file_path}")),
  do: import_config(config_file_path)
