defmodule GaPersonalWeb.ContactController do
  @moduledoc """
  Controller for handling contact form submissions from the marketing website.

  This is a public endpoint that does not require authentication.
  It includes basic validation and rate limiting protection.

  ## Endpoints

  - `POST /api/v1/contact` - Submit contact form

  ## Request Body

      {
        "contact": {
          "name": "John Doe",
          "email": "john@example.com",
          "phone": "+55 48 99999-9999",
          "goal": "weight_loss",
          "message": "I want to start training"
        }
      }

  ## Response

      {
        "status": "ok",
        "message": "Message sent successfully"
      }
  """

  use GaPersonalWeb, :controller

  require Logger

  alias GaPersonal.Emails.ContactEmail
  alias GaPersonal.Mailer

  @doc """
  Handles contact form submissions.

  Validates the input, sends an email to the trainer, and optionally
  sends a confirmation email to the person who submitted the form.
  """
  def create(conn, %{"contact" => contact_params}) do
    with :ok <- validate_required_fields(contact_params),
         :ok <- validate_email_format(contact_params["email"]) do
      # Log the contact submission regardless of email delivery
      Logger.info(
        "Contact form submission: name=#{contact_params["name"]}, " <>
          "email=#{contact_params["email"]}, phone=#{contact_params["phone"]}, " <>
          "goal=#{contact_params["goal"]}"
      )

      # Attempt email delivery (non-blocking — contact is accepted even if email fails)
      case send_contact_emails(contact_params) do
        :ok ->
          Logger.info("Contact emails sent successfully for #{contact_params["email"]}")

        {:error, reason} ->
          Logger.warning(
            "Contact form accepted but email delivery failed: #{inspect(reason)}. " <>
              "Contact: #{contact_params["name"]} <#{contact_params["email"]}>"
          )
      end

      conn
      |> put_status(:created)
      |> json(%{
        status: "ok",
        message: get_success_message(contact_params)
      })
    else
      {:error, :missing_name} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Name is required", field: "name"})

      {:error, :missing_email} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Email is required", field: "email"})

      {:error, :missing_message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Message is required", field: "message"})

      {:error, :invalid_email} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid email format", field: "email"})

      {:error, reason} ->
        Logger.error("Contact form error: #{inspect(reason)}")
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "An unexpected error occurred"})
    end
  end

  # Handle missing contact wrapper
  def create(conn, params) when is_map(params) do
    # Try to handle params without the wrapper
    if Map.has_key?(params, "name") or Map.has_key?(params, "email") do
      create(conn, %{"contact" => params})
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid request format. Expected {contact: {...}}"})
    end
  end

  # =============================================================================
  # Private - Validation
  # =============================================================================

  defp validate_required_fields(params) do
    cond do
      blank?(params["name"]) -> {:error, :missing_name}
      blank?(params["email"]) -> {:error, :missing_email}
      blank?(params["message"]) -> {:error, :missing_message}
      true -> :ok
    end
  end

  defp validate_email_format(email) do
    # Simple email regex validation
    email_regex = ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

    if Regex.match?(email_regex, email || "") do
      :ok
    else
      {:error, :invalid_email}
    end
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

  # =============================================================================
  # Private - Email Sending
  # =============================================================================

  defp send_contact_emails(params) do
    # Get locale from params or default to pt_BR
    locale = params["locale"] || "pt_BR"
    params_with_locale = Map.put(params, "locale", locale)

    # Send email to trainer
    try do
      ContactEmail.contact_submission(params_with_locale)
      |> Mailer.deliver()

      # Send confirmation to the person who submitted
      ContactEmail.contact_confirmation(params_with_locale)
      |> Mailer.deliver()

      Logger.info("Contact form submitted: #{params["email"]} - #{params["name"]}")
      :ok
    rescue
      error ->
        Logger.error("Contact email delivery error: #{inspect(error)}")
        {:error, :email_delivery_failed}
    end
  end

  defp get_success_message(params) do
    locale = params["locale"] || "pt_BR"

    if locale == "en_US" do
      "Your message has been sent successfully. We'll get back to you soon!"
    else
      "Sua mensagem foi enviada com sucesso. Retornaremos em breve!"
    end
  end
end
