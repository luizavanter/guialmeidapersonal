defmodule GaPersonal.MixProject do
  use Mix.Project

  def project do
    [
      app: :ga_personal,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {GaPersonal.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:dns_cluster, "~> 0.2.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.3"},
      {:gettext, "~> 0.24"},
      # Email
      {:swoosh, "~> 1.21"},
      {:resend, "~> 0.4.0"},
      {:finch, "~> 0.18"},
      # HTTP client (for Asaas API, GCS)
      {:req, "~> 0.5"},
      # Google Cloud auth (GCS signed URLs)
      {:goth, "~> 1.4"},
      # Background jobs
      {:oban, "~> 2.18"},
      {:ex_machina, "~> 2.8", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run #{__DIR__}/priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
