defmodule ZombieDriver.MixProject do
  use Mix.Project

  @description """
  The Zombie Driver service is a microservice that determines if a driver is a zombie or not.
  """

  def project do
    [
      app: :zombie_driver,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: "Zombie Driver",
      description: @description,
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ZombieDriver, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support/"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:logger_file_backend, "~> 0.0.10"},
      {:redix, "~> 0.9.0"},
      {:timex, "~> 3.4"},
      # Interacting via HTTP
      {:httpoison, "~> 1.5", override: true},
      {:jason, "~> 1.1"},
      # Linters
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      # Testing
      {:mock, "~> 0.3.0", only: :test},
      {:junit_formatter, "~> 3.0", only: :test},
      {:excoveralls, "~> 0.10.3", only: :test},
      # Deployment
      {:distillery, "~> 2.0", runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Andrey Krisanov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/akrisanov/microservices_in_elixir/"
      }
    ]
  end
end
