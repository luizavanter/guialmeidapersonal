defmodule GaPersonalWeb.WebhookController do
  @moduledoc """
  Controller for handling external webhook events.

  Currently supports:
  - Cal.com webhooks for appointment scheduling
  """

  use GaPersonalWeb, :controller

  require Logger

  alias GaPersonal.Schedule
  alias GaPersonal.Accounts
  alias GaPersonal.Finance

  @calcom_events ~w(BOOKING_CREATED BOOKING_CANCELLED BOOKING_RESCHEDULED)

  @doc """
  Handle Cal.com webhook events.

  Supported events:
  - BOOKING_CREATED: Creates a new appointment
  - BOOKING_CANCELLED: Cancels an existing appointment
  - BOOKING_RESCHEDULED: Updates appointment time

  ## Security
  Validates the webhook signature using the calcom-webhook-secret.
  """
  def calcom(conn, params) do
    with :ok <- verify_calcom_signature(conn),
         {:ok, event_type} <- get_event_type(params),
         :ok <- process_calcom_event(event_type, params) do
      json(conn, %{status: "ok", message: "Webhook processed successfully"})
    else
      {:error, :invalid_signature} ->
        Logger.warning("Cal.com webhook: Invalid signature")
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid webhook signature"})

      {:error, :unknown_event} ->
        Logger.info("Cal.com webhook: Unknown event type, ignoring")
        json(conn, %{status: "ok", message: "Event type not supported"})

      {:error, reason} ->
        Logger.error("Cal.com webhook error: #{inspect(reason)}")
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to process webhook", details: inspect(reason)})
    end
  end

  # Verify Cal.com webhook signature
  defp verify_calcom_signature(conn) do
    case get_webhook_secret() do
      nil ->
        # In development, skip signature verification if secret not configured
        if Application.get_env(:ga_personal_web, :env) == :dev do
          Logger.warning("Cal.com webhook: Skipping signature verification in dev mode")
          :ok
        else
          {:error, :invalid_signature}
        end

      secret ->
        signature = get_req_header(conn, "x-cal-signature-256") |> List.first()
        body = conn.assigns[:raw_body] || ""

        if valid_signature?(body, signature, secret) do
          :ok
        else
          {:error, :invalid_signature}
        end
    end
  end

  defp get_webhook_secret do
    System.get_env("CALCOM_WEBHOOK_SECRET")
  end

  defp valid_signature?(body, signature, secret) when is_binary(signature) do
    expected = "sha256=" <> (:crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower))
    Plug.Crypto.secure_compare(expected, signature)
  end

  defp valid_signature?(_body, _signature, _secret), do: false

  defp get_event_type(%{"triggerEvent" => event_type}) when event_type in @calcom_events do
    {:ok, event_type}
  end

  defp get_event_type(%{"triggerEvent" => event_type}) do
    Logger.info("Cal.com webhook: Received unsupported event type: #{event_type}")
    {:error, :unknown_event}
  end

  defp get_event_type(_params) do
    {:error, :unknown_event}
  end

  # Process BOOKING_CREATED event
  defp process_calcom_event("BOOKING_CREATED", %{"payload" => payload}) do
    Logger.info("Cal.com webhook: Processing BOOKING_CREATED")

    with {:ok, appointment_params} <- extract_appointment_params(payload),
         {:ok, _appointment} <- Schedule.create_appointment(appointment_params) do
      Logger.info("Cal.com webhook: Appointment created successfully")
      :ok
    end
  end

  # Process BOOKING_CANCELLED event
  defp process_calcom_event("BOOKING_CANCELLED", %{"payload" => payload}) do
    Logger.info("Cal.com webhook: Processing BOOKING_CANCELLED")

    calcom_uid = get_in(payload, ["uid"])
    cancellation_reason = get_in(payload, ["cancellationReason"]) || "Cancelled via Cal.com"

    case find_appointment_by_calcom_uid(calcom_uid) do
      nil ->
        Logger.warning("Cal.com webhook: Appointment not found for uid: #{calcom_uid}")
        :ok

      appointment ->
        case Schedule.cancel_appointment(appointment, cancellation_reason) do
          {:ok, _updated} ->
            Logger.info("Cal.com webhook: Appointment cancelled successfully")
            :ok

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # Process BOOKING_RESCHEDULED event
  defp process_calcom_event("BOOKING_RESCHEDULED", %{"payload" => payload}) do
    Logger.info("Cal.com webhook: Processing BOOKING_RESCHEDULED")

    calcom_uid = get_in(payload, ["uid"])
    new_start_time = get_in(payload, ["startTime"])

    case find_appointment_by_calcom_uid(calcom_uid) do
      nil ->
        Logger.warning("Cal.com webhook: Appointment not found for uid: #{calcom_uid}")
        :ok

      appointment ->
        case parse_datetime(new_start_time) do
          {:ok, scheduled_at} ->
            case Schedule.update_appointment(appointment, %{scheduled_at: scheduled_at}) do
              {:ok, _updated} ->
                Logger.info("Cal.com webhook: Appointment rescheduled successfully")
                :ok

              {:error, reason} ->
                {:error, reason}
            end

          {:error, _} ->
            {:error, :invalid_datetime}
        end
    end
  end

  defp process_calcom_event(event_type, _params) do
    Logger.warning("Cal.com webhook: Unhandled event type: #{event_type}")
    {:error, :unknown_event}
  end

  # Extract appointment parameters from Cal.com payload
  defp extract_appointment_params(payload) do
    # Cal.com payload structure
    # {
    #   "uid": "unique-booking-id",
    #   "startTime": "2024-01-15T10:00:00Z",
    #   "endTime": "2024-01-15T11:00:00Z",
    #   "title": "Personal Training Session",
    #   "attendees": [{"email": "student@example.com", "name": "Student Name"}],
    #   "organizer": {"email": "trainer@example.com", "name": "Trainer Name"},
    #   "metadata": {"student_id": "uuid", "trainer_id": "uuid"},
    #   "location": "Gym Address"
    # }

    start_time = get_in(payload, ["startTime"])
    end_time = get_in(payload, ["endTime"])

    with {:ok, scheduled_at} <- parse_datetime(start_time),
         {:ok, duration_minutes} <- calculate_duration(start_time, end_time),
         {:ok, trainer_id} <- get_trainer_id(payload),
         {:ok, student_id} <- get_student_id(payload) do
      params = %{
        "trainer_id" => trainer_id,
        "student_id" => student_id,
        "scheduled_at" => scheduled_at,
        "duration_minutes" => duration_minutes,
        "status" => "scheduled",
        "appointment_type" => get_appointment_type(payload),
        "location" => get_in(payload, ["location"]),
        "notes" => build_notes(payload)
      }

      {:ok, params}
    end
  end

  defp parse_datetime(nil), do: {:error, :missing_datetime}

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, _} -> {:error, :invalid_datetime}
    end
  end

  defp calculate_duration(start_time, end_time) do
    with {:ok, start_dt, _} <- DateTime.from_iso8601(start_time),
         {:ok, end_dt, _} <- DateTime.from_iso8601(end_time) do
      diff_seconds = DateTime.diff(end_dt, start_dt)
      {:ok, div(diff_seconds, 60)}
    else
      _ -> {:ok, 60} # Default to 60 minutes if calculation fails
    end
  end

  defp get_trainer_id(payload) do
    # Try to get trainer_id from metadata first
    case get_in(payload, ["metadata", "trainer_id"]) do
      nil ->
        # Fall back to looking up by organizer email
        organizer_email = get_in(payload, ["organizer", "email"])
        find_user_id_by_email(organizer_email, :trainer)

      trainer_id ->
        {:ok, trainer_id}
    end
  end

  defp get_student_id(payload) do
    # Try to get student_id from metadata first
    case get_in(payload, ["metadata", "student_id"]) do
      nil ->
        # Fall back to looking up by attendee email
        attendees = get_in(payload, ["attendees"]) || []
        attendee_email = get_in(attendees, [Access.at(0), "email"])
        find_user_id_by_email(attendee_email, :student)

      student_id ->
        {:ok, student_id}
    end
  end

  defp find_user_id_by_email(nil, _role), do: {:error, :missing_email}

  defp find_user_id_by_email(email, role) do
    case Accounts.get_user_by_email(email) do
      nil -> {:error, {:user_not_found, email}}
      user ->
        if user.role == to_string(role) or role == :any do
          {:ok, user.id}
        else
          {:error, {:invalid_role, email, role}}
        end
    end
  end

  defp find_appointment_by_calcom_uid(nil), do: nil

  defp find_appointment_by_calcom_uid(uid) do
    # Search in notes field for Cal.com UID
    # This is a simple implementation - in production you might want
    # to add a calcom_uid field to the appointments table
    Schedule.find_appointment_by_notes_containing("cal.com:#{uid}")
  end

  defp get_appointment_type(payload) do
    title = get_in(payload, ["title"]) || ""
    event_type = get_in(payload, ["eventType", "title"]) || ""

    cond do
      String.contains?(String.downcase(title), "assessment") -> "assessment"
      String.contains?(String.downcase(title), "evaluation") -> "assessment"
      String.contains?(String.downcase(event_type), "assessment") -> "assessment"
      true -> "training"
    end
  end

  defp build_notes(payload) do
    uid = get_in(payload, ["uid"])
    title = get_in(payload, ["title"])
    description = get_in(payload, ["description"])
    attendee_notes = get_in(payload, ["attendees", Access.at(0), "notes"])

    notes = ["cal.com:#{uid}"]

    notes =
      if title, do: notes ++ ["Title: #{title}"], else: notes

    notes =
      if description && description != "", do: notes ++ ["Description: #{description}"], else: notes

    notes =
      if attendee_notes && attendee_notes != "", do: notes ++ ["Attendee notes: #{attendee_notes}"], else: notes

    Enum.join(notes, "\n")
  end

  # ── Asaas Webhook ──────────────────────────────────────────────

  @asaas_payment_events ~w(PAYMENT_CONFIRMED PAYMENT_RECEIVED PAYMENT_OVERDUE PAYMENT_REFUNDED PAYMENT_DELETED)

  @doc """
  Handle Asaas webhook events for payment status updates.

  Asaas sends POST requests with:
    - event: Event type (e.g. "PAYMENT_CONFIRMED")
    - payment: Payment object with id, status, value, etc.
  """
  def asaas(conn, params) do
    with :ok <- verify_asaas_token(conn),
         {:ok, event} <- get_asaas_event(params),
         :ok <- process_asaas_event(event, params) do
      json(conn, %{status: "ok"})
    else
      {:error, :invalid_token} ->
        Logger.warning("Asaas webhook: Invalid access token")
        conn |> put_status(:unauthorized) |> json(%{error: "Invalid token"})

      {:error, :unknown_event} ->
        json(conn, %{status: "ok", message: "Event not handled"})

      {:error, reason} ->
        Logger.error("Asaas webhook error: #{inspect(reason)}")
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Processing failed"})
    end
  end

  defp verify_asaas_token(conn) do
    expected = Application.get_env(:ga_personal, :asaas)[:webhook_token]

    cond do
      is_nil(expected) ->
        Logger.warning("Asaas webhook: No webhook token configured, accepting all")
        :ok

      true ->
        token = get_req_header(conn, "asaas-access-token") |> List.first()

        if Plug.Crypto.secure_compare(expected || "", token || "") do
          :ok
        else
          {:error, :invalid_token}
        end
    end
  end

  defp get_asaas_event(%{"event" => event}) when event in @asaas_payment_events, do: {:ok, event}
  defp get_asaas_event(%{"event" => _}), do: {:error, :unknown_event}
  defp get_asaas_event(_), do: {:error, :unknown_event}

  defp process_asaas_event(event, %{"payment" => payment_data}) do
    asaas_charge_id = payment_data["id"]
    Logger.info("Asaas webhook: #{event} for charge #{asaas_charge_id}")

    case Finance.get_payment_by_asaas_charge_id(asaas_charge_id) do
      nil ->
        Logger.warning("Asaas webhook: No local payment found for charge #{asaas_charge_id}")
        :ok

      payment ->
        new_status = asaas_status_to_local(event)
        attrs = %{status: new_status}

        attrs =
          if event in ["PAYMENT_CONFIRMED", "PAYMENT_RECEIVED"] do
            Map.put(attrs, :payment_date, Date.utc_today())
          else
            attrs
          end

        case Finance.update_payment(payment, attrs) do
          {:ok, _updated} ->
            Logger.info("Asaas webhook: Updated payment #{payment.id} to #{new_status}")
            :ok

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp process_asaas_event(_event, _params) do
    Logger.warning("Asaas webhook: Missing payment data")
    :ok
  end

  defp asaas_status_to_local("PAYMENT_CONFIRMED"), do: "completed"
  defp asaas_status_to_local("PAYMENT_RECEIVED"), do: "completed"
  defp asaas_status_to_local("PAYMENT_OVERDUE"), do: "pending"
  defp asaas_status_to_local("PAYMENT_REFUNDED"), do: "refunded"
  defp asaas_status_to_local("PAYMENT_DELETED"), do: "failed"
  defp asaas_status_to_local(_), do: "pending"
end
