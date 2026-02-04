defmodule GaPersonal.Emails.ContactEmail do
  @moduledoc """
  Email templates for contact form submissions.

  Sends contact form data to the trainer's email address.
  Supports bilingual content based on the form submission language.

  ## Usage

      alias GaPersonal.Emails.ContactEmail
      alias GaPersonal.Mailer

      params = %{
        name: "John Doe",
        email: "john@example.com",
        phone: "+55 48 99999-9999",
        goal: "weight_loss",
        message: "I want to lose 10kg",
        locale: "pt_BR"
      }

      ContactEmail.contact_submission(params)
      |> Mailer.deliver()
  """

  import Swoosh.Email

  @trainer_email "guilherme@gapersonal.com"
  @trainer_name "Guilherme Almeida"

  @doc """
  Creates a contact form submission email.

  The email is sent to the trainer with all contact form details.
  A copy is also sent to the person who submitted the form.

  ## Parameters

  - `params` - Map with contact form data:
    - `name` - Sender's name (required)
    - `email` - Sender's email (required)
    - `phone` - Sender's phone (optional)
    - `goal` - Selected goal (optional)
    - `message` - Message content (required)
    - `locale` - Language preference (optional, defaults to "pt_BR")
  """
  def contact_submission(params) do
    locale = Map.get(params, :locale) || Map.get(params, "locale") || "pt_BR"
    name = get_param(params, :name)
    email = get_param(params, :email)
    phone = get_param(params, :phone)
    goal = get_param(params, :goal)
    message = get_param(params, :message)

    {subject, body} = contact_submission_content(locale, name, email, phone, goal, message)

    new()
    |> to({@trainer_name, @trainer_email})
    |> from(from_address())
    |> reply_to({name, email})
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  @doc """
  Creates a confirmation email for the person who submitted the contact form.

  ## Parameters

  - `params` - Same params as `contact_submission/1`
  """
  def contact_confirmation(params) do
    locale = Map.get(params, :locale) || Map.get(params, "locale") || "pt_BR"
    name = get_param(params, :name)
    email = get_param(params, :email)

    {subject, body} = contact_confirmation_content(locale, name)

    new()
    |> to({name, email})
    |> from(from_address())
    |> subject(subject)
    |> html_body(body)
    |> text_body(strip_html(body))
  end

  # =============================================================================
  # Private - Email Content
  # =============================================================================

  defp contact_submission_content("en_US", name, email, phone, goal, message) do
    goal_label = translate_goal(goal, "en_US")

    subject = "New Contact from Website - #{name}"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">New Contact Form Submission</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      You received a new message from your website:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;">
        <strong style="color: #C4F53A;">Name:</strong> #{name}
      </p>
      <p style="color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;">
        <strong style="color: #C4F53A;">Email:</strong> <a href="mailto:#{email}" style="color: #0EA5E9;">#{email}</a>
      </p>
      #{if phone && phone != "", do: "<p style=\"color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;\"><strong style=\"color: #C4F53A;\">Phone:</strong> #{phone}</p>", else: ""}
      #{if goal_label, do: "<p style=\"color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;\"><strong style=\"color: #C4F53A;\">Goal:</strong> #{goal_label}</p>", else: ""}
    </div>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 14px; margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 1px;">Message:</p>
      <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6; margin: 0; white-space: pre-wrap;">#{message}</p>
    </div>
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      Reply directly to this email to respond to #{name}.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp contact_submission_content(_locale, name, email, phone, goal, message) do
    goal_label = translate_goal(goal, "pt_BR")

    subject = "Novo Contato do Site - #{name}"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Novo Contato do Formulario</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Voce recebeu uma nova mensagem do seu site:
    </p>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;">
        <strong style="color: #C4F53A;">Nome:</strong> #{name}
      </p>
      <p style="color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;">
        <strong style="color: #C4F53A;">Email:</strong> <a href="mailto:#{email}" style="color: #0EA5E9;">#{email}</a>
      </p>
      #{if phone && phone != "", do: "<p style=\"color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;\"><strong style=\"color: #C4F53A;\">Telefone:</strong> #{phone}</p>", else: ""}
      #{if goal_label, do: "<p style=\"color: #F5F5F0; font-size: 16px; margin: 0 0 12px 0;\"><strong style=\"color: #C4F53A;\">Objetivo:</strong> #{goal_label}</p>", else: ""}
    </div>
    <div style="background-color: #1a1a1a; padding: 20px; border-radius: 8px; margin: 24px 0;">
      <p style="color: #C4F53A; font-size: 14px; margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 1px;">Mensagem:</p>
      <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6; margin: 0; white-space: pre-wrap;">#{message}</p>
    </div>
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      Responda diretamente a este email para responder a #{name}.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp contact_confirmation_content("en_US", name) do
    subject = "We received your message - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Thank you for reaching out!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Hi #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      We received your message and will get back to you as soon as possible, usually within 24-48 hours.
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      In the meantime, feel free to explore our services and learn more about how we can help you achieve your fitness goals.
    </p>
    #{email_button("Explore Our Services", "https://guialmeidapersonal.esp.br/services")}
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      This is an automated confirmation. Please do not reply to this email.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  defp contact_confirmation_content(_locale, name) do
    subject = "Recebemos sua mensagem - GA Personal"

    body = """
    #{email_header()}
    <h1 style="color: #C4F53A; margin-bottom: 24px;">Obrigado por entrar em contato!</h1>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Ola #{name},
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Recebemos sua mensagem e retornaremos o mais breve possivel, geralmente em 24-48 horas.
    </p>
    <p style="color: #F5F5F0; font-size: 16px; line-height: 1.6;">
      Enquanto isso, sinta-se a vontade para explorar nossos servicos e saber mais sobre como podemos ajuda-lo a alcancar seus objetivos fitness.
    </p>
    #{email_button("Explorar Servicos", "https://guialmeidapersonal.esp.br/servicos")}
    <p style="color: #888; font-size: 14px; margin-top: 32px;">
      Esta e uma confirmacao automatica. Por favor, nao responda a este email.
    </p>
    #{email_footer()}
    """

    {subject, body}
  end

  # =============================================================================
  # Private - Helpers
  # =============================================================================

  defp from_address do
    config = Application.get_env(:ga_personal, :mailer_from, [])
    {config[:name] || "GA Personal", config[:email] || "noreply@guialmeidapersonal.esp.br"}
  end

  defp get_param(params, key) when is_atom(key) do
    Map.get(params, key) || Map.get(params, to_string(key))
  end

  defp translate_goal(nil, _locale), do: nil
  defp translate_goal("", _locale), do: nil

  defp translate_goal(goal, "en_US") do
    case goal do
      "weight_loss" -> "Weight Loss"
      "muscle_gain" -> "Muscle Gain"
      "conditioning" -> "Conditioning"
      "hybrid" -> "Hybrid Training"
      "other" -> "Other"
      _ -> goal
    end
  end

  defp translate_goal(goal, _locale) do
    case goal do
      "weight_loss" -> "Perda de Peso"
      "muscle_gain" -> "Ganho de Massa"
      "conditioning" -> "Condicionamento"
      "hybrid" -> "Treinamento Hibrido"
      "other" -> "Outro"
      _ -> goal
    end
  end

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
end
