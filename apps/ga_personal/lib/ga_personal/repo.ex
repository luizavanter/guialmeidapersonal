defmodule GaPersonal.Repo do
  use Ecto.Repo,
    otp_app: :ga_personal,
    adapter: Ecto.Adapters.Postgres
end
