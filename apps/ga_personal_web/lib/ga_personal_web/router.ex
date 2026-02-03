defmodule GaPersonalWeb.Router do
  use GaPersonalWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug,
      origin: [
        # Development
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:3003",
        # Production - esp.br domain
        "https://guialmeidapersonal.esp.br",
        "https://www.guialmeidapersonal.esp.br",
        "https://admin.guialmeidapersonal.esp.br",
        "https://app.guialmeidapersonal.esp.br",
        # Production - com.br domain (future)
        "https://guialmeidapersonal.com.br",
        "https://www.guialmeidapersonal.com.br",
        "https://admin.guialmeidapersonal.com.br",
        "https://app.guialmeidapersonal.com.br"
      ],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      headers: ["Authorization", "Content-Type", "Accept", "Origin", "User-Agent", "X-Requested-With"]
  end

  pipeline :authenticated do
    plug GaPersonalWeb.AuthPipeline
  end

  scope "/api/v1", GaPersonalWeb do
    pipe_through :api

    # Public routes - Authentication
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
  end

  scope "/api/v1", GaPersonalWeb do
    pipe_through [:api, :authenticated]

    # Auth - protected
    get "/auth/me", AuthController, :me

    # Students
    resources "/students", StudentController, except: [:new, :edit]

    # Appointments
    resources "/appointments", AppointmentController, except: [:new, :edit]

    # Exercises
    resources "/exercises", ExerciseController, except: [:new, :edit]

    # Workout Plans
    resources "/workout-plans", WorkoutPlanController, except: [:new, :edit]

    # Workout Logs
    resources "/workout-logs", WorkoutLogController, only: [:index, :create, :show]

    # Body Assessments
    resources "/body-assessments", BodyAssessmentController, except: [:new, :edit]

    # Goals
    resources "/goals", GoalController, except: [:new, :edit]

    # Plans (subscription plans)
    resources "/plans", PlanController, except: [:new, :edit]

    # Subscriptions
    resources "/subscriptions", SubscriptionController, except: [:new, :edit]

    # Payments
    resources "/payments", PaymentController, only: [:index, :create, :show, :update]

    # Messages
    resources "/messages", MessageController, only: [:index, :create, :show, :delete]
    get "/messages/inbox", MessageController, :inbox
    get "/messages/sent", MessageController, :sent

    # Notifications
    resources "/notifications", NotificationController, only: [:index, :show, :update, :delete]
    post "/notifications/:id/read", NotificationController, :mark_read

    # Blog Posts
    resources "/blog-posts", BlogPostController, except: [:new, :edit]

    # Testimonials
    resources "/testimonials", TestimonialController, except: [:new, :edit]

    # FAQs
    resources "/faqs", FAQController, except: [:new, :edit]
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:ga_personal_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: GaPersonalWeb.Telemetry
    end
  end
end
