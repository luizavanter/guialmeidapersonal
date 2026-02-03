# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :ga_personal,
  ecto_repos: [GaPersonal.Repo]

config :ga_personal_web,
  ecto_repos: [GaPersonal.Repo],
  generators: [context_app: :ga_personal]

# Configures the endpoint
config :ga_personal_web, GaPersonalWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: GaPersonalWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GaPersonal.PubSub,
  live_view: [signing_salt: "q54Qcw3v"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Guardian
config :ga_personal, GaPersonal.Guardian,
  issuer: "ga_personal",
  secret_key: "eWpJA8rLGjQ2N5hPvMwXkF7sD9bT6cZ3nV0xY1uR4iO8aK5mE2qH7jS3fG6lB9pC"

# Configure Gettext
config :ga_personal, GaPersonal.Gettext,
  default_locale: "pt_BR",
  locales: ~w(pt_BR en_US)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
