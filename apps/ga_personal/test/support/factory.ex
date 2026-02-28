defmodule GaPersonal.Factory do
  use ExMachina.Ecto, repo: GaPersonal.Repo

  alias GaPersonal.Accounts.{User, StudentProfile, RefreshToken}
  alias GaPersonal.Schedule.{TimeSlot, Appointment}
  alias GaPersonal.Workouts.{Exercise, WorkoutPlan, WorkoutExercise, WorkoutLog}
  alias GaPersonal.Evolution.{BodyAssessment, EvolutionPhoto, Goal}
  alias GaPersonal.Finance.{Plan, Subscription, Payment}
  alias GaPersonal.Messaging.{Message, Notification}
  alias GaPersonal.Content.{BlogPost, Testimonial, FAQ}

  # ── Accounts ──────────────────────────────────────────

  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@example.com"),
      full_name: sequence(:full_name, &"User #{&1}"),
      password: "Password123!",
      password_hash: Bcrypt.hash_pwd_salt("Password123!"),
      role: "trainer",
      phone: "+5548999990000",
      locale: "pt_BR",
      active: true
    }
  end

  def trainer_factory do
    struct!(user_factory(), %{role: "trainer"})
  end

  def student_user_factory do
    struct!(user_factory(), %{role: "student"})
  end

  def admin_factory do
    struct!(user_factory(), %{role: "admin"})
  end

  def student_profile_factory do
    trainer = build(:trainer)
    student = build(:student_user)

    %StudentProfile{
      user: student,
      trainer: trainer,
      date_of_birth: ~D[1990-05-15],
      gender: "male",
      emergency_contact_name: "Emergency Contact",
      emergency_contact_phone: "+5548999991111",
      medical_conditions: "None",
      goals_description: "Build muscle and improve endurance",
      notes: "Prefers morning sessions",
      status: "active"
    }
  end

  def refresh_token_factory do
    raw_token = RefreshToken.generate_token()

    %RefreshToken{
      token_hash: RefreshToken.hash_token(raw_token),
      user: build(:user),
      expires_at: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.truncate(:second)
    }
  end

  # ── Schedule ──────────────────────────────────────────

  def time_slot_factory do
    %TimeSlot{
      trainer: build(:trainer),
      day_of_week: Enum.random(0..6),
      start_time: ~T[08:00:00],
      end_time: ~T[09:00:00],
      slot_duration_minutes: 60,
      is_available: true
    }
  end

  def appointment_factory do
    %Appointment{
      trainer: build(:trainer),
      student: build(:student_user),
      scheduled_at: DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.truncate(:second),
      duration_minutes: 60,
      status: "scheduled",
      appointment_type: "personal_training",
      location: "Studio A"
    }
  end

  # ── Workouts ──────────────────────────────────────────

  def exercise_factory do
    %Exercise{
      trainer: build(:trainer),
      name: sequence(:exercise_name, &"Exercise #{&1}"),
      description: "A strength training exercise",
      category: "strength",
      muscle_groups: ["chest", "triceps"],
      equipment_needed: ["barbell", "bench"],
      difficulty_level: "intermediate",
      instructions: "Perform with controlled movement",
      is_public: false
    }
  end

  def workout_plan_factory do
    %WorkoutPlan{
      trainer: build(:trainer),
      student: build(:student_user),
      name: sequence(:plan_name, &"Workout Plan #{&1}"),
      description: "A comprehensive training program",
      duration_weeks: 8,
      sessions_per_week: 3,
      difficulty_level: "intermediate",
      goals: ["muscle_gain", "strength"],
      status: "draft",
      is_template: false
    }
  end

  def workout_exercise_factory do
    %WorkoutExercise{
      workout_plan: build(:workout_plan),
      exercise: build(:exercise),
      day_number: 1,
      order_in_workout: 1,
      sets: 3,
      reps: "10-12",
      weight: "60kg",
      rest_seconds: 90,
      notes: "Focus on form"
    }
  end

  def workout_log_factory do
    %WorkoutLog{
      student: build(:student_user),
      exercise: build(:exercise),
      workout_plan: build(:workout_plan),
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      sets_completed: 3,
      reps_completed: "10,10,8",
      weight_used: "60kg",
      duration_seconds: 300,
      difficulty_rating: 3,
      notes: "Good session"
    }
  end

  # ── Evolution ─────────────────────────────────────────

  def body_assessment_factory do
    %BodyAssessment{
      student: build(:student_user),
      trainer: build(:trainer),
      assessment_date: Date.utc_today(),
      weight_kg: Decimal.new("80.5"),
      height_cm: Decimal.new("178.0"),
      body_fat_percentage: Decimal.new("18.5"),
      muscle_mass_kg: Decimal.new("35.2"),
      bmi: Decimal.new("25.4"),
      waist_cm: Decimal.new("85.0"),
      chest_cm: Decimal.new("100.0"),
      resting_heart_rate: 68,
      blood_pressure_systolic: 120,
      blood_pressure_diastolic: 80
    }
  end

  def evolution_photo_factory do
    %EvolutionPhoto{
      student: build(:student_user),
      body_assessment: build(:body_assessment),
      photo_url: sequence(:photo_url, &"https://storage.example.com/photos/photo_#{&1}.jpg"),
      photo_type: "front",
      taken_at: Date.utc_today(),
      notes: "Monthly progress photo"
    }
  end

  def goal_factory do
    %Goal{
      student: build(:student_user),
      trainer: build(:trainer),
      goal_type: "weight_loss",
      title: sequence(:goal_title, &"Goal #{&1}"),
      description: "Lose body fat while maintaining muscle",
      target_value: Decimal.new("75.0"),
      current_value: Decimal.new("80.5"),
      unit: "kg",
      start_date: Date.utc_today(),
      target_date: Date.utc_today() |> Date.add(90),
      status: "active"
    }
  end

  # ── Finance ───────────────────────────────────────────

  def plan_factory do
    %Plan{
      trainer: build(:trainer),
      name: sequence(:plan_name, &"Plan #{&1}"),
      description: "Monthly personal training",
      price_cents: 15_000,
      currency: "BRL",
      billing_period: "monthly",
      sessions_included: 12,
      features: ["Personal training", "Workout plans", "Progress tracking"],
      is_active: true,
      is_public: true
    }
  end

  def subscription_factory do
    %Subscription{
      student: build(:student_user),
      plan: build(:plan),
      trainer: build(:trainer),
      status: "active",
      start_date: Date.utc_today(),
      end_date: Date.utc_today() |> Date.add(30),
      next_billing_date: Date.utc_today() |> Date.add(30),
      sessions_remaining: 12,
      auto_renew: true
    }
  end

  def payment_factory do
    %Payment{
      student: build(:student_user),
      trainer: build(:trainer),
      amount_cents: 15_000,
      currency: "BRL",
      status: "pending",
      payment_method: "pix",
      due_date: Date.utc_today() |> Date.add(5)
    }
  end

  # ── Messaging ─────────────────────────────────────────

  def message_factory do
    %Message{
      sender: build(:trainer),
      recipient: build(:student_user),
      subject: sequence(:message_subject, &"Message #{&1}"),
      body: "Hello, here is your updated workout plan.",
      is_read: false
    }
  end

  def notification_factory do
    %Notification{
      user: build(:student_user),
      type: "appointment_reminder",
      title: "Upcoming Session",
      body: "You have a training session tomorrow at 8:00 AM",
      action_url: "/appointments",
      delivery_method: "in_app",
      is_read: false
    }
  end

  # ── Content ───────────────────────────────────────────

  def blog_post_factory do
    %BlogPost{
      trainer: build(:trainer),
      title: sequence(:blog_title, &"Blog Post #{&1}"),
      slug: sequence(:blog_slug, &"blog-post-#{&1}"),
      content: "This is a comprehensive article about fitness and health.",
      excerpt: "A brief summary of the article.",
      status: "draft",
      tags: ["fitness", "health"],
      view_count: 0
    }
  end

  def testimonial_factory do
    %Testimonial{
      trainer: build(:trainer),
      student: build(:student_user),
      author_name: sequence(:author_name, &"Student #{&1}"),
      content: "Amazing trainer! Completely changed my fitness journey.",
      rating: 5,
      is_featured: false,
      is_approved: false
    }
  end

  def faq_factory do
    %FAQ{
      trainer: build(:trainer),
      question: sequence(:faq_question, &"What is question #{&1}?"),
      answer: "This is the answer to the question.",
      category: "general",
      display_order: 0,
      is_published: true
    }
  end
end
