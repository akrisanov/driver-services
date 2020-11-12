# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :gateway,
  endpoints_config: "test/fixtures/config.yaml"

config :junit_formatter,
  report_file: "junit.xml",
  report_dir: "/tmp",
  print_report_file: true
