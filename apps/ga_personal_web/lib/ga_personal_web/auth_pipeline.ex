defmodule GaPersonalWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :ga_personal,
    module: GaPersonal.Guardian,
    error_handler: GaPersonalWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
