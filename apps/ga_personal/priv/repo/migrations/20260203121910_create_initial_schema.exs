defmodule GaPersonal.Repo.Migrations.CreateInitialSchema do
  use Ecto.Migration

  def change do
    # Enable UUID extension
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", "DROP EXTENSION IF EXISTS \"uuid-ossp\""

    # Users table (base for authentication)
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :role, :string, null: false  # "trainer", "student", "admin"
      add :full_name, :string, null: false
      add :phone, :string
      add :locale, :string, default: "pt_BR"
      add :active, :boolean, default: true
      add :last_login_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
    create index(:users, [:active])

    # Student Profiles (extends user for students)
    create table(:student_profiles, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :trainer_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :date_of_birth, :date
      add :gender, :string
      add :emergency_contact_name, :string
      add :emergency_contact_phone, :string
      add :medical_conditions, :text
      add :goals_description, :text
      add :notes, :text  # Trainer's private notes
      add :status, :string, default: "active"  # "active", "paused", "cancelled"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:student_profiles, [:user_id])
    create index(:student_profiles, [:trainer_id])
    create index(:student_profiles, [:status])

    # Time Slots (trainer availability)
    create table(:time_slots, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :day_of_week, :integer, null: false  # 0=Sunday, 1=Monday, etc.
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :slot_duration_minutes, :integer, default: 60
      add :is_available, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:time_slots, [:trainer_id])
    create index(:time_slots, [:day_of_week])

    # Appointments
    create table(:appointments, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :student_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :scheduled_at, :utc_datetime, null: false
      add :duration_minutes, :integer, default: 60
      add :status, :string, default: "scheduled"  # "scheduled", "completed", "cancelled", "no_show"
      add :appointment_type, :string  # "personal_training", "assessment", "consultation"
      add :location, :string
      add :notes, :text
      add :cancellation_reason, :text
      add :cancelled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:appointments, [:trainer_id])
    create index(:appointments, [:student_id])
    create index(:appointments, [:scheduled_at])
    create index(:appointments, [:status])

    # Exercises Library
    create table(:exercises, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :name, :string, null: false
      add :description, :text
      add :category, :string  # "strength", "cardio", "flexibility", "balance"
      add :muscle_groups, {:array, :string}, default: []
      add :equipment_needed, {:array, :string}, default: []
      add :difficulty_level, :string  # "beginner", "intermediate", "advanced"
      add :video_url, :string
      add :thumbnail_url, :string
      add :instructions, :text
      add :is_public, :boolean, default: false  # Public exercises shared across trainers

      timestamps(type: :utc_datetime)
    end

    create index(:exercises, [:trainer_id])
    create index(:exercises, [:category])
    create index(:exercises, [:is_public])

    # Workout Plans
    create table(:workout_plans, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :student_id, references(:users, type: :uuid, on_delete: :restrict)
      add :name, :string, null: false
      add :description, :text
      add :duration_weeks, :integer
      add :sessions_per_week, :integer
      add :difficulty_level, :string
      add :goals, {:array, :string}, default: []
      add :status, :string, default: "draft"  # "draft", "active", "completed", "archived"
      add :started_at, :date
      add :completed_at, :date
      add :is_template, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:workout_plans, [:trainer_id])
    create index(:workout_plans, [:student_id])
    create index(:workout_plans, [:status])

    # Workout Plan Exercises (join table with additional fields)
    create table(:workout_exercises, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :workout_plan_id, references(:workout_plans, type: :uuid, on_delete: :delete_all), null: false
      add :exercise_id, references(:exercises, type: :uuid, on_delete: :restrict), null: false
      add :day_number, :integer  # Which day of the plan (1-7)
      add :order_in_workout, :integer  # Order within the day
      add :sets, :integer
      add :reps, :string  # Can be "12" or "10-12" or "AMRAP"
      add :weight, :string
      add :duration_seconds, :integer
      add :rest_seconds, :integer
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:workout_exercises, [:workout_plan_id])
    create index(:workout_exercises, [:exercise_id])

    # Workout Logs (student's completed workouts)
    create table(:workout_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :student_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :workout_plan_id, references(:workout_plans, type: :uuid, on_delete: :nilify_all)
      add :exercise_id, references(:exercises, type: :uuid, on_delete: :restrict), null: false
      add :completed_at, :utc_datetime, null: false
      add :sets_completed, :integer
      add :reps_completed, :string
      add :weight_used, :string
      add :duration_seconds, :integer
      add :difficulty_rating, :integer  # 1-5 scale
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:workout_logs, [:student_id])
    create index(:workout_logs, [:workout_plan_id])
    create index(:workout_logs, [:completed_at])

    # Body Assessments
    create table(:body_assessments, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :student_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :trainer_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :assessment_date, :date, null: false

      # Body measurements
      add :weight_kg, :decimal, precision: 5, scale: 2
      add :height_cm, :decimal, precision: 5, scale: 2
      add :body_fat_percentage, :decimal, precision: 4, scale: 2
      add :muscle_mass_kg, :decimal, precision: 5, scale: 2
      add :bmi, :decimal, precision: 4, scale: 2

      # Circumferences (cm)
      add :neck_cm, :decimal, precision: 5, scale: 2
      add :chest_cm, :decimal, precision: 5, scale: 2
      add :waist_cm, :decimal, precision: 5, scale: 2
      add :hips_cm, :decimal, precision: 5, scale: 2
      add :right_arm_cm, :decimal, precision: 5, scale: 2
      add :left_arm_cm, :decimal, precision: 5, scale: 2
      add :right_thigh_cm, :decimal, precision: 5, scale: 2
      add :left_thigh_cm, :decimal, precision: 5, scale: 2
      add :right_calf_cm, :decimal, precision: 5, scale: 2
      add :left_calf_cm, :decimal, precision: 5, scale: 2

      # Additional metrics
      add :resting_heart_rate, :integer
      add :blood_pressure_systolic, :integer
      add :blood_pressure_diastolic, :integer

      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:body_assessments, [:student_id])
    create index(:body_assessments, [:assessment_date])

    # Evolution Photos
    create table(:evolution_photos, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :student_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :body_assessment_id, references(:body_assessments, type: :uuid, on_delete: :nilify_all)
      add :photo_url, :string, null: false
      add :photo_type, :string, null: false  # "front", "back", "side", "other"
      add :taken_at, :date, null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:evolution_photos, [:student_id])
    create index(:evolution_photos, [:taken_at])

    # Goals
    create table(:goals, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :student_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :trainer_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :goal_type, :string, null: false  # "weight_loss", "muscle_gain", "strength", "endurance", "flexibility", "custom"
      add :title, :string, null: false
      add :description, :text
      add :target_value, :decimal, precision: 10, scale: 2
      add :current_value, :decimal, precision: 10, scale: 2
      add :unit, :string  # "kg", "lbs", "%", "cm", etc.
      add :start_date, :date, null: false
      add :target_date, :date
      add :status, :string, default: "active"  # "active", "achieved", "abandoned"
      add :achieved_at, :date

      timestamps(type: :utc_datetime)
    end

    create index(:goals, [:student_id])
    create index(:goals, [:status])

    # Plans (subscription packages)
    create table(:plans, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :price_cents, :integer, null: false
      add :currency, :string, default: "BRL"
      add :billing_period, :string, null: false  # "weekly", "monthly", "quarterly", "yearly", "one_time"
      add :sessions_included, :integer  # Number of sessions per billing period
      add :features, {:array, :string}, default: []
      add :is_active, :boolean, default: true
      add :is_public, :boolean, default: true  # Show on public pricing page

      timestamps(type: :utc_datetime)
    end

    create index(:plans, [:trainer_id])
    create index(:plans, [:is_active])

    # Subscriptions
    create table(:subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :student_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :plan_id, references(:plans, type: :uuid, on_delete: :restrict), null: false
      add :trainer_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :status, :string, default: "active"  # "active", "paused", "cancelled", "expired"
      add :start_date, :date, null: false
      add :end_date, :date
      add :next_billing_date, :date
      add :sessions_remaining, :integer
      add :auto_renew, :boolean, default: true
      add :cancellation_reason, :text
      add :cancelled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:student_id])
    create index(:subscriptions, [:trainer_id])
    create index(:subscriptions, [:status])

    # Payments
    create table(:payments, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :student_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :trainer_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :subscription_id, references(:subscriptions, type: :uuid, on_delete: :nilify_all)
      add :amount_cents, :integer, null: false
      add :currency, :string, default: "BRL"
      add :status, :string, default: "pending"  # "pending", "completed", "failed", "refunded"
      add :payment_method, :string  # "cash", "pix", "credit_card", "debit_card", "bank_transfer"
      add :payment_date, :date
      add :due_date, :date
      add :reference_number, :string
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:payments, [:student_id])
    create index(:payments, [:trainer_id])
    create index(:payments, [:status])
    create index(:payments, [:payment_date])

    # Messages
    create table(:messages, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :sender_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :recipient_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      add :subject, :string
      add :body, :text, null: false
      add :is_read, :boolean, default: false
      add :read_at, :utc_datetime
      add :parent_message_id, references(:messages, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:sender_id])
    create index(:messages, [:recipient_id])
    create index(:messages, [:is_read])
    create index(:messages, [:inserted_at])

    # Notifications
    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :type, :string, null: false  # "appointment_reminder", "payment_due", "new_message", "goal_achieved", etc.
      add :title, :string, null: false
      add :body, :text, null: false
      add :action_url, :string
      add :is_read, :boolean, default: false
      add :read_at, :utc_datetime
      add :sent_at, :utc_datetime
      add :delivery_method, :string  # "in_app", "email", "sms", "push"

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:is_read])
    create index(:notifications, [:type])

    # Blog Posts (content management)
    create table(:blog_posts, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :text, null: false
      add :excerpt, :text
      add :featured_image_url, :string
      add :status, :string, default: "draft"  # "draft", "published", "archived"
      add :published_at, :utc_datetime
      add :tags, {:array, :string}, default: []
      add :view_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blog_posts, [:slug])
    create index(:blog_posts, [:trainer_id])
    create index(:blog_posts, [:status])

    # Testimonials
    create table(:testimonials, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :student_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :author_name, :string, null: false
      add :author_photo_url, :string
      add :content, :text, null: false
      add :rating, :integer  # 1-5 stars
      add :is_featured, :boolean, default: false
      add :is_approved, :boolean, default: false
      add :approved_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:testimonials, [:trainer_id])
    create index(:testimonials, [:is_approved])
    create index(:testimonials, [:is_featured])

    # FAQs
    create table(:faqs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :question, :string, null: false
      add :answer, :text, null: false
      add :category, :string
      add :display_order, :integer, default: 0
      add :is_published, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:faqs, [:trainer_id])
    create index(:faqs, [:category])

    # System Settings
    create table(:system_settings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :trainer_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :key, :string, null: false
      add :value, :text
      add :value_type, :string  # "string", "integer", "boolean", "json"
      add :category, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:system_settings, [:trainer_id, :key])
    create index(:system_settings, [:trainer_id])

    # Audit Logs
    create table(:audit_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :action, :string, null: false
      add :resource_type, :string
      add :resource_id, :uuid
      add :changes, :map
      add :ip_address, :string
      add :user_agent, :string

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:resource_type, :resource_id])
    create index(:audit_logs, [:inserted_at])
  end
end
