defmodule GaPersonal.Emails.UserEmail do
  @moduledoc """
  Email templates for user-related notifications.

  All emails support bilingual content (PT-BR and EN-US) based on user preferences.

  ## Available Emails

  - `welcome/1` - Welcome email for new users
  - `password_reset/2` - Password reset instructions
  - `password_changed/1` - Password change confirmation
  - `appointment_confirmation/2` - Appointment booking confirmation
  - `appointment_reminder/2` - Appointment reminder (24h before)
  - `appointment_cancelled/2` - Appointment cancellation notice
  - `payment_reminder/2` - Payment due reminder
  - `payment_received/2` - Payment confirmation
  - `new_workout_plan/2` - New workout plan assigned
  - `assessment_scheduled/2` - Body assessment scheduled

  ## Usage

      alias GaPersonal.Emails.UserEmail
      alias GaPersonal.Mailer

      # Send welcome email
      user
      |> UserEmail.welcome()
      |> Mailer.deliver()

      # Send appointment reminder
      user
      |> UserEmail.appointment_reminder(appointment)
      |> Mailer.deliver_later()
  """

  import Swoosh.Email

  @doc """
  Returns the default from address configured for the application.
  """
  def from_address do
    config = Application.get_env(:ga_personal, :mailer_from, [])
    {config[:name] || "GA Personal", config[:email] || "noreply@guialmeidapersonal.esp.br"}
  end

  @doc """
  Creates a welcome email for a new user.

  ## Parameters

  - `user` - User struct with `email`, `full_name`, and optionally `locale`

  ## Example

      UserEmail.welcome(%{email: "user@example.com", full_name: "John Doe", locale: "en_US"})
  """
  def welcome(user) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = welcome_content(locale, user.full_name)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a password reset email with reset link.

  ## Parameters

  - `user` - User struct
  - `reset_token` - Password reset token

  ## Example

      UserEmail.password_reset(user, "abc123token")
  """
  def password_reset(user, reset_token) do
    locale = Map.get(user, :locale, "pt_BR")
    reset_url = "https://app.guialmeidapersonal.esp.br/reset-password?token=#{reset_token}"

    {subject, body} = password_reset_content(locale, user.full_name, reset_url)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a password changed confirmation email.

  ## Parameters

  - `user` - User struct
  """
  def password_changed(user) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = password_changed_content(locale, user.full_name)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates an appointment confirmation email.

  ## Parameters

  - `user` - User struct
  - `appointment` - Appointment struct with `scheduled_at` and `duration_minutes`
  """
  def appointment_confirmation(user, appointment) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = appointment_confirmation_content(locale, user.full_name, appointment)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates an appointment reminder email (sent 24h before).

  ## Parameters

  - `user` - User struct
  - `appointment` - Appointment struct
  """
  def appointment_reminder(user, appointment) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = appointment_reminder_content(locale, user.full_name, appointment)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates an appointment cancellation email.

  ## Parameters

  - `user` - User struct
  - `appointment` - Appointment struct
  """
  def appointment_cancelled(user, appointment) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = appointment_cancelled_content(locale, user.full_name, appointment)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a payment reminder email.

  ## Parameters

  - `user` - User struct
  - `payment` - Payment struct with `amount_cents`, `due_date`
  """
  def payment_reminder(user, payment) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = payment_reminder_content(locale, user.full_name, payment)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a payment received confirmation email.

  ## Parameters

  - `user` - User struct
  - `payment` - Payment struct
  """
  def payment_received(user, payment) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = payment_received_content(locale, user.full_name, payment)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a new workout plan notification email.

  ## Parameters

  - `user` - User struct
  - `workout_plan` - WorkoutPlan struct with `name`, `description`
  """
  def new_workout_plan(user, workout_plan) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = new_workout_plan_content(locale, user.full_name, workout_plan)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a body assessment scheduled email.

  ## Parameters

  - `user` - User struct
  - `assessment` - Assessment details with date
  """
  def assessment_scheduled(user, assessment) do
    locale = Map.get(user, :locale, "pt_BR")

    {subject, body} = assessment_scheduled_content(locale, user.full_name, assessment)

    new()
    |> to({user.full_name, user.email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  # =============================================================================
  # Private - Email Content Templates
  # =============================================================================

  defp welcome_content("en_US", name) do
    subject = "Welcome to GA Personal!"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Welcome, #{name}!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Thank you for joining GA Personal. We're excited to help you achieve your fitness goals!
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      With your account, you can:
    </p>
    <ul style="color: #F5F5F0; font-size: 16px; line-height: 1.8;">
      <li>View and track your workout plans</li>
      <li>Schedule and manage your training sessions</li>
      <li>Track your body evolution and progress</li>
      <li>Communicate directly with your personal trainer</li>
    </ul>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6; margin-top: 24px;">
      Access your portal anytime at:
    </p>
    #{email_button("Access My Portal", "https://app.guialmeidapersonal.esp.br")}
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      If you have any questions, feel free to reach out to your trainer through the app.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp welcome_content(_locale, name) do
    subject = "Bem-vindo ao GA Personal!"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Bem-vindo, #{name}!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Obrigado por se juntar ao GA Personal. Estamos animados em ajudar você a alcançar seus objetivos fitness!
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Com sua conta, você pode:
    </p>
    <ul style="color: #F5F5F0; font-size: 16px; line-height: 1.8;">
      <li>Visualizar e acompanhar seus planos de treino</li>
      <li>Agendar e gerenciar suas sessões de treinamento</li>
      <li>Acompanhar sua evolução corporal e progresso</li>
      <li>Comunicar-se diretamente com seu personal trainer</li>
    </ul>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6; margin-top: 24px;">
      Acesse seu portal a qualquer momento em:
    </p>
    #{email_button("Acessar Meu Portal", "https://app.guialmeidapersonal.esp.br")}
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      Se tiver alguma duvida, entre em contato com seu trainer pelo app.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp password_reset_content("en_US", name, reset_url) do
    subject = "Reset Your Password - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Password Reset Request</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      We received a request to reset your password. Click the button below to create a new password:
    </p>
    #{email_button("Reset My Password", reset_url)}
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      This link will expire in 1 hour. If you didn't request this, you can safely ignore this email.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp password_reset_content(_locale, name, reset_url) do
    subject = "Redefinir Sua Senha - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Solicitacao de Redefinicao de Senha</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Recebemos uma solicitacao para redefinir sua senha. Clique no botao abaixo para criar uma nova senha:
    </p>
    #{email_button("Redefinir Minha Senha", reset_url)}
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      Este link expira em 1 hora. Se voce nao solicitou isso, pode ignorar este email com seguranca.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp password_changed_content("en_US", name) do
    subject = "Your Password Was Changed - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Password Changed Successfully</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Your password has been successfully changed. You can now log in with your new password.
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      If you didn't make this change, please contact us immediately.
    </p>
    #{email_button("Go to Login", "https://app.guialmeidapersonal.esp.br/login")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp password_changed_content(_locale, name) do
    subject = "Sua Senha Foi Alterada - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Senha Alterada com Sucesso</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Sua senha foi alterada com sucesso. Voce ja pode fazer login com sua nova senha.
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Se voce nao fez esta alteracao, entre em contato conosco imediatamente.
    </p>
    #{email_button("Ir para Login", "https://app.guialmeidapersonal.esp.br/login")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp appointment_confirmation_content("en_US", name, appointment) do
    date = format_datetime(appointment.scheduled_at, "en_US")
    duration = appointment.duration_minutes

    subject = "Appointment Confirmed - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Appointment Confirmed!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Your training session has been confirmed:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 18px; margin: 0 0 8px 0;"><strong>Date & Time:</strong> #{date}</p>
      <p style="color: #F5F5F0; font-size: 16px; margin: 0;"><strong>Duration:</strong> #{duration} minutes</p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Please arrive 5-10 minutes early. If you need to reschedule, please do so at least 24 hours in advance.
    </p>
    #{email_button("View My Schedule", "https://app.guialmeidapersonal.esp.br/schedule")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp appointment_confirmation_content(_locale, name, appointment) do
    date = format_datetime(appointment.scheduled_at, "pt_BR")
    duration = appointment.duration_minutes

    subject = "Agendamento Confirmado - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Agendamento Confirmado!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Sua sessao de treino foi confirmada:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 18px; margin: 0 0 8px 0;"><strong>Data e Hora:</strong> #{date}</p>
      <p style="color: #F5F5F0; font-size: 16px; margin: 0;"><strong>Duracao:</strong> #{duration} minutos</p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Por favor, chegue 5-10 minutos antes. Se precisar reagendar, faca isso com pelo menos 24 horas de antecedencia.
    </p>
    #{email_button("Ver Minha Agenda", "https://app.guialmeidapersonal.esp.br/schedule")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp appointment_reminder_content("en_US", name, appointment) do
    date = format_datetime(appointment.scheduled_at, "en_US")

    subject = "Reminder: Training Tomorrow - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Training Session Tomorrow!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      This is a friendly reminder about your upcoming training session:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 18px; margin: 0;"><strong>#{date}</strong></p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Don't forget to:
    </p>
    <ul style="color: #F5F5F0; font-size: 16px; line-height: 1.8;">
      <li>Get a good night's sleep</li>
      <li>Stay hydrated</li>
      <li>Bring your workout gear</li>
    </ul>
    #{email_button("View Details", "https://app.guialmeidapersonal.esp.br/schedule")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp appointment_reminder_content(_locale, name, appointment) do
    date = format_datetime(appointment.scheduled_at, "pt_BR")

    subject = "Lembrete: Treino Amanha - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Sessao de Treino Amanha!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Este e um lembrete amigavel sobre sua proxima sessao de treino:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 18px; margin: 0;"><strong>#{date}</strong></p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Nao esqueca de:
    </p>
    <ul style="color: #F5F5F0; font-size: 16px; line-height: 1.8;">
      <li>Ter uma boa noite de sono</li>
      <li>Manter-se hidratado</li>
      <li>Trazer suas roupas de treino</li>
    </ul>
    #{email_button("Ver Detalhes", "https://app.guialmeidapersonal.esp.br/schedule")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp appointment_cancelled_content("en_US", name, appointment) do
    date = format_datetime(appointment.scheduled_at, "en_US")

    subject = "Appointment Cancelled - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Appointment Cancelled</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Your training session scheduled for <strong>#{date}</strong> has been cancelled.
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      If you'd like to reschedule, please book a new session through your portal.
    </p>
    #{email_button("Book New Session", "https://app.guialmeidapersonal.esp.br/schedule")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp appointment_cancelled_content(_locale, name, appointment) do
    date = format_datetime(appointment.scheduled_at, "pt_BR")

    subject = "Agendamento Cancelado - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Agendamento Cancelado</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Sua sessao de treino agendada para <strong>#{date}</strong> foi cancelada.
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Se desejar reagendar, por favor agende uma nova sessao pelo seu portal.
    </p>
    #{email_button("Agendar Nova Sessao", "https://app.guialmeidapersonal.esp.br/schedule")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp payment_reminder_content("en_US", name, payment) do
    amount = format_currency(payment.amount_cents, "en_US")
    due_date = format_date(payment.due_date, "en_US")

    subject = "Payment Reminder - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Payment Reminder</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      This is a friendly reminder about your upcoming payment:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 24px; margin: 0 0 8px 0;"><strong>#{amount}</strong></p>
      <p style="color: #F5F5F0; font-size: 16px; margin: 0;">Due: #{due_date}</p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Please make your payment by the due date to keep your subscription active.
    </p>
    #{email_button("View Payment Details", "https://app.guialmeidapersonal.esp.br/payments")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp payment_reminder_content(_locale, name, payment) do
    amount = format_currency(payment.amount_cents, "pt_BR")
    due_date = format_date(payment.due_date, "pt_BR")

    subject = "Lembrete de Pagamento - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Lembrete de Pagamento</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Este e um lembrete amigavel sobre seu proximo pagamento:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 24px; margin: 0 0 8px 0;"><strong>#{amount}</strong></p>
      <p style="color: #F5F5F0; font-size: 16px; margin: 0;">Vencimento: #{due_date}</p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Por favor, efetue o pagamento ate a data de vencimento para manter sua assinatura ativa.
    </p>
    #{email_button("Ver Detalhes do Pagamento", "https://app.guialmeidapersonal.esp.br/payments")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp payment_received_content("en_US", name, payment) do
    amount = format_currency(payment.amount_cents, "en_US")

    subject = "Payment Received - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Payment Received!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      We've received your payment. Thank you!
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 24px; margin: 0;"><strong>#{amount}</strong></p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Your subscription is active and you're all set for your training sessions!
    </p>
    #{email_button("Go to Dashboard", "https://app.guialmeidapersonal.esp.br")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp payment_received_content(_locale, name, payment) do
    amount = format_currency(payment.amount_cents, "pt_BR")

    subject = "Pagamento Recebido - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Pagamento Recebido!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Recebemos seu pagamento. Obrigado!
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 24px; margin: 0;"><strong>#{amount}</strong></p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Sua assinatura esta ativa e voce esta pronto para suas sessoes de treino!
    </p>
    #{email_button("Ir para Dashboard", "https://app.guialmeidapersonal.esp.br")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp new_workout_plan_content("en_US", name, workout_plan) do
    subject = "New Workout Plan Assigned - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">New Workout Plan!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Your trainer has assigned you a new workout plan:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 20px; margin: 0 0 8px 0;"><strong>#{workout_plan.name}</strong></p>
      #{if workout_plan.description, do: "<p style=\"color: #F5F5F0; font-size: 14px; margin: 0;\">#{workout_plan.description}</p>", else: ""}
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Check out your new plan and start crushing your goals!
    </p>
    #{email_button("View My Workout Plan", "https://app.guialmeidapersonal.esp.br/workouts")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp new_workout_plan_content(_locale, name, workout_plan) do
    subject = "Novo Plano de Treino Atribuido - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Novo Plano de Treino!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Seu trainer atribuiu um novo plano de treino para voce:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 20px; margin: 0 0 8px 0;"><strong>#{workout_plan.name}</strong></p>
      #{if workout_plan.description, do: "<p style=\"color: #F5F5F0; font-size: 14px; margin: 0;\">#{workout_plan.description}</p>", else: ""}
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Confira seu novo plano e comece a atingir seus objetivos!
    </p>
    #{email_button("Ver Meu Plano de Treino", "https://app.guialmeidapersonal.esp.br/workouts")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp assessment_scheduled_content("en_US", name, assessment) do
    date = format_datetime(assessment.scheduled_at, "en_US")

    subject = "Body Assessment Scheduled - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Assessment Scheduled!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Your body assessment has been scheduled:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 18px; margin: 0;"><strong>#{date}</strong></p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      For best results:
    </p>
    <ul style="color: #F5F5F0; font-size: 16px; line-height: 1.8;">
      <li>Fast for 2-3 hours before</li>
      <li>Avoid intense exercise the day before</li>
      <li>Stay well hydrated</li>
      <li>Wear comfortable, light clothing</li>
    </ul>
    #{email_button("View My Evolution", "https://app.guialmeidapersonal.esp.br/evolution")}
    #{email_footer()}
    """

    {subject, body}
  end

  defp assessment_scheduled_content(_locale, name, assessment) do
    date = format_datetime(assessment.scheduled_at, "pt_BR")

    subject = "Avaliacao Fisica Agendada - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Avaliacao Agendada!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Sua avaliacao fisica foi agendada:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 18px; margin: 0;"><strong>#{date}</strong></p>
    </div>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Para melhores resultados:
    </p>
    <ul style="color: #F5F5F0; font-size: 16px; line-height: 1.8;">
      <li>Faca jejum de 2-3 horas antes</li>
      <li>Evite exercicios intensos no dia anterior</li>
      <li>Mantenha-se bem hidratado</li>
      <li>Use roupas confortaveis e leves</li>
    </ul>
    #{email_button("Ver Minha Evolucao", "https://app.guialmeidapersonal.esp.br/evolution")}
    #{email_footer()}
    """

    {subject, body}
  end

  # =============================================================================
  # Private - Helpers
  # =============================================================================

  defp email_header do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; background-color: #0A0A0A; font-family: 'Outfit', Arial, sans-serif;">
      <div style="max-width: 600px; margin: 0 auto; padding: 40px 20px;">
        <div style="text-align: center; margin-bottom: 32px;">
          <h2 style="color: #C4F53A; font-family: 'Bebas Neue', Arial, sans-serif; font-size: 32px; letter-spacing: 2px; margin: 0;">GA PERSONAL</h2>
        </div>
        <div style="background-color: #111; border-radius: 12px; padding: 32px;">
    """
  end

  defp email_footer do
    """
        </div>
        <div style="text-align: center; margin-top: 32px; padding-top: 24px; border-top: 1px solid #333;">
          <p style="color: #666; font-size: 12px; margin: 0 0 8px 0;">
            GA Personal - Guilherme Almeida
          </p>
          <p style="color: #666; font-size: 12px; margin: 0 0 8px 0;">
            Jurere, Florianopolis/SC - Brasil
          </p>
          <p style="color: #666; font-size: 12px; margin: 0;">
            <a href="https://guialmeidapersonal.esp.br" style="color: #C4F53A; text-decoration: none;">guialmeidapersonal.esp.br</a>
          </p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp email_button(text, url) do
    """
    <div style="text-align: center; margin: 32px 0;">
      <a href="#{url}" style="display: inline-block; background-color: #C4F53A; color: #0A0A0A; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 16px;">
        #{text}
      </a>
    </div>
    """
  end

  defp strip_html(html) do
    html
    |> String.replace(~r/<style[^>]*>.*?<\/style>/s, "")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp format_datetime(datetime, "en_US") do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  defp format_datetime(datetime, _locale) do
    Calendar.strftime(datetime, "%d/%m/%Y as %H:%M")
  end

  defp format_date(date, "en_US") do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp format_date(date, _locale) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  defp format_currency(amount_cents, "en_US") do
    amount = amount_cents / 100
    "R$ #{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  defp format_currency(amount_cents, _locale) do
    amount = amount_cents / 100
    formatted = :erlang.float_to_binary(amount, decimals: 2)
    "R$ #{String.replace(formatted, ".", ",")}"
  end
end
