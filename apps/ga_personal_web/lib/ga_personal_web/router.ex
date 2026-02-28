defmodule GaPersonalWeb.Router do
  use GaPersonalWeb, :router

  alias GaPersonalWeb.Plugs.{RequireRole, LoadCurrentUser, RateLimit}

  pipeline :api do
    plug :accepts, ["json"]
    # CORS is handled at the endpoint level for OPTIONS preflight support
  end

  pipeline :rate_limit_auth do
    plug RateLimit, limit: 5, period: 60_000, key_prefix: "auth"
  end

  pipeline :rate_limit_contact do
    plug RateLimit, limit: 3, period: 60_000, key_prefix: "contact"
  end

  pipeline :rate_limit_refresh do
    plug RateLimit, limit: 10, period: 60_000, key_prefix: "refresh"
  end

  pipeline :authenticated do
    plug GaPersonalWeb.AuthPipeline
    plug LoadCurrentUser
  end

  # Role-based authorization pipelines
  pipeline :trainer_or_admin do
    plug RequireRole, [:trainer, :admin]
  end

  pipeline :student_only do
    plug RequireRole, [:student]
  end

  pipeline :any_authenticated do
    # Any authenticated user (trainer, student, admin)
    plug RequireRole, [:trainer, :student, :admin]
  end

  # Health check - no auth, no rate limiting
  scope "/api/v1", GaPersonalWeb do
    pipe_through :api

    get "/health", HealthController, :check
  end

  # Public auth routes with rate limiting
  scope "/api/v1", GaPersonalWeb do
    pipe_through [:api, :rate_limit_auth]

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/logout", AuthController, :logout
  end

  # Token refresh with separate rate limit
  scope "/api/v1", GaPersonalWeb do
    pipe_through [:api, :rate_limit_refresh]

    post "/auth/refresh", AuthController, :refresh
  end

  # Contact form with rate limiting
  scope "/api/v1", GaPersonalWeb do
    pipe_through [:api, :rate_limit_contact]

    post "/contact", ContactController, :create
  end

  # Webhooks - no rate limiting (external integrations)
  scope "/api/v1", GaPersonalWeb do
    pipe_through :api

    post "/webhooks/calcom", WebhookController, :calcom
  end

  # Routes accessible by any authenticated user
  scope "/api/v1", GaPersonalWeb do
    pipe_through [:api, :authenticated, :any_authenticated]

    # Auth - protected (get current user info)
    get "/auth/me", AuthController, :me

    # Messages - all authenticated users can use messaging
    resources "/messages", MessageController, only: [:index, :create, :show, :delete]
    get "/messages/inbox", MessageController, :inbox
    get "/messages/sent", MessageController, :sent

    # Notifications - all users receive notifications
    post "/notifications/read-all", NotificationController, :mark_all_read
    resources "/notifications", NotificationController, only: [:index, :show, :update, :delete]
    post "/notifications/:id/read", NotificationController, :mark_read
  end

  # Trainer/Admin only routes - managing the business
  scope "/api/v1", GaPersonalWeb do
    pipe_through [:api, :authenticated, :trainer_or_admin]

    # Students management - trainers manage their students
    resources "/students", StudentController, except: [:new, :edit]

    # Appointments management - trainers manage schedule
    resources "/appointments", AppointmentController, except: [:new, :edit]

    # Exercise library - trainers manage exercises
    resources "/exercises", ExerciseController, except: [:new, :edit]

    # Workout Plans - trainers create and manage plans
    resources "/workout-plans", WorkoutPlanController, except: [:new, :edit]

    # Plans (subscription/pricing plans) - trainers manage pricing
    resources "/plans", PlanController, except: [:new, :edit]

    # Subscriptions - trainers manage student subscriptions
    resources "/subscriptions", SubscriptionController, except: [:new, :edit]

    # Payments - trainers track payments
    resources "/payments", PaymentController, only: [:index, :create, :show, :update]

    # Body Assessments - trainers create assessments for students
    resources "/body-assessments", BodyAssessmentController, except: [:new, :edit]

    # Goals - trainers set goals for students
    resources "/goals", GoalController, except: [:new, :edit]

    # Content management - trainers manage their content
    resources "/blog-posts", BlogPostController, except: [:new, :edit]
    resources "/testimonials", TestimonialController, except: [:new, :edit]
    resources "/faqs", FAQController, except: [:new, :edit]
  end

  # Student-accessible routes (read-only or limited write)
  scope "/api/v1/student", GaPersonalWeb do
    pipe_through [:api, :authenticated, :student_only]

    # Students can view their own workout plans
    get "/workout-plans", WorkoutPlanController, :index_for_student
    get "/workout-plans/:id", WorkoutPlanController, :show_for_student

    # Students can create workout logs (record their exercises)
    resources "/workout-logs", WorkoutLogController, only: [:index, :create, :show]

    # Students can view their appointments
    get "/appointments", AppointmentController, :index_for_student
    get "/appointments/:id", AppointmentController, :show_for_student

    # Students can view their body assessments
    get "/body-assessments", BodyAssessmentController, :index_for_student
    get "/body-assessments/:id", BodyAssessmentController, :show_for_student

    # Students can view and update their goals progress
    get "/goals", GoalController, :index_for_student
    get "/goals/:id", GoalController, :show_for_student
    put "/goals/:id/progress", GoalController, :update_progress

    # Students can view their subscription and payment history
    get "/subscription", SubscriptionController, :show_for_student
    get "/payments", PaymentController, :index_for_student
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
