defmodule GaPersonal.Mailer do
  @moduledoc """
  Mailer module for sending emails via Resend.

  This module uses Swoosh with the Resend adapter for transactional emails.
  Configuration is loaded from environment variables in production.

  ## Usage

      alias GaPersonal.Mailer
      alias GaPersonal.Emails.UserEmail

      # Send welcome email
      UserEmail.welcome(user)
      |> Mailer.deliver()

      # Send async (returns immediately)
      UserEmail.welcome(user)
      |> Mailer.deliver_later()
  """

  use Swoosh.Mailer, otp_app: :ga_personal
end
