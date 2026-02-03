# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GaPersonal.Repo.insert!(%GaPersonal.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias GaPersonal.Repo
alias GaPersonal.Accounts
alias GaPersonal.Workouts

# Clear existing data (only in development)
if Mix.env() == :dev do
  IO.puts("Clearing existing data...")
  Repo.delete_all(GaPersonal.Accounts.StudentProfile)
  Repo.delete_all(GaPersonal.Accounts.User)
  Repo.delete_all(GaPersonal.Workouts.Exercise)
end

IO.puts("Creating trainer account...")

# Create trainer account (Guilherme Almeida)
{:ok, trainer} = Accounts.create_user(%{
  email: "guilherme@gapersonal.com",
  password: "trainer123",
  full_name: "Guilherme Almeida",
  role: "trainer",
  phone: "+55 48 99999-9999",
  locale: "pt_BR",
  active: true
})

IO.puts("Trainer created: #{trainer.email}")

IO.puts("Creating test students...")

# Create test students
{:ok, student1} = Accounts.create_student(trainer.id, %{
  "email" => "maria.silva@example.com",
  "password" => "student123",
  "full_name" => "Maria Silva",
  "phone" => "+55 48 98888-8888",
  "date_of_birth" => ~D[1990-05-15],
  "gender" => "female",
  "goals_description" => "Perder peso e ganhar condicionamento físico",
  "medical_conditions" => "Nenhuma",
  "emergency_contact_name" => "João Silva",
  "emergency_contact_phone" => "+55 48 97777-7777",
  "status" => "active"
})

{:ok, student2} = Accounts.create_student(trainer.id, %{
  "email" => "carlos.santos@example.com",
  "password" => "student123",
  "full_name" => "Carlos Santos",
  "phone" => "+55 48 96666-6666",
  "date_of_birth" => ~D[1985-10-20],
  "gender" => "male",
  "goals_description" => "Ganhar massa muscular e força",
  "medical_conditions" => "Leve dor no joelho direito",
  "emergency_contact_name" => "Ana Santos",
  "emergency_contact_phone" => "+55 48 95555-5555",
  "status" => "active"
})

IO.puts("Created #{elem(student1, 1).user.full_name}")
IO.puts("Created #{elem(student2, 1).user.full_name}")

IO.puts("Creating exercise library...")

# Exercise library - Strength exercises
exercises = [
  # Upper Body - Chest
  %{
    name: "Supino Reto com Barra",
    description: "Exercício fundamental para desenvolvimento do peitoral",
    category: "strength",
    muscle_groups: ["chest", "triceps", "shoulders"],
    equipment_needed: ["barbell", "bench"],
    difficulty_level: "intermediate",
    instructions: "Deite no banco, segure a barra na largura dos ombros, desça até o peito e empurre para cima",
    is_public: true
  },
  %{
    name: "Supino Inclinado com Halteres",
    description: "Foco na porção superior do peitoral",
    category: "strength",
    muscle_groups: ["chest", "shoulders"],
    equipment_needed: ["dumbbells", "incline_bench"],
    difficulty_level: "intermediate",
    is_public: true
  },
  %{
    name: "Flexão de Braços",
    description: "Exercício clássico de peso corporal",
    category: "strength",
    muscle_groups: ["chest", "triceps", "core"],
    equipment_needed: [],
    difficulty_level: "beginner",
    is_public: true
  },

  # Upper Body - Back
  %{
    name: "Puxada Frontal",
    description: "Desenvolvimento das costas e largura",
    category: "strength",
    muscle_groups: ["back", "biceps"],
    equipment_needed: ["cable_machine"],
    difficulty_level: "beginner",
    is_public: true
  },
  %{
    name: "Remada Curvada com Barra",
    description: "Espessura das costas",
    category: "strength",
    muscle_groups: ["back", "biceps"],
    equipment_needed: ["barbell"],
    difficulty_level: "intermediate",
    is_public: true
  },
  %{
    name: "Barra Fixa",
    description: "Exercício completo para costas",
    category: "strength",
    muscle_groups: ["back", "biceps", "core"],
    equipment_needed: ["pull_up_bar"],
    difficulty_level: "advanced",
    is_public: true
  },

  # Upper Body - Shoulders
  %{
    name: "Desenvolvimento com Halteres",
    description: "Desenvolvimento completo dos ombros",
    category: "strength",
    muscle_groups: ["shoulders", "triceps"],
    equipment_needed: ["dumbbells"],
    difficulty_level: "intermediate",
    is_public: true
  },
  %{
    name: "Elevação Lateral",
    description: "Isolamento do deltoide lateral",
    category: "strength",
    muscle_groups: ["shoulders"],
    equipment_needed: ["dumbbells"],
    difficulty_level: "beginner",
    is_public: true
  },

  # Upper Body - Arms
  %{
    name: "Rosca Direta com Barra",
    description: "Desenvolvimento dos bíceps",
    category: "strength",
    muscle_groups: ["biceps"],
    equipment_needed: ["barbell"],
    difficulty_level: "beginner",
    is_public: true
  },
  %{
    name: "Tríceps Testa",
    description: "Isolamento do tríceps",
    category: "strength",
    muscle_groups: ["triceps"],
    equipment_needed: ["barbell", "bench"],
    difficulty_level: "intermediate",
    is_public: true
  },

  # Lower Body - Legs
  %{
    name: "Agachamento Livre",
    description: "Rei dos exercícios para pernas",
    category: "strength",
    muscle_groups: ["quadriceps", "glutes", "hamstrings"],
    equipment_needed: ["barbell", "squat_rack"],
    difficulty_level: "intermediate",
    is_public: true
  },
  %{
    name: "Leg Press 45°",
    description: "Desenvolvimento geral das pernas",
    category: "strength",
    muscle_groups: ["quadriceps", "glutes"],
    equipment_needed: ["leg_press_machine"],
    difficulty_level: "beginner",
    is_public: true
  },
  %{
    name: "Levantamento Terra",
    description: "Exercício completo para corpo todo",
    category: "strength",
    muscle_groups: ["back", "glutes", "hamstrings", "core"],
    equipment_needed: ["barbell"],
    difficulty_level: "advanced",
    is_public: true
  },
  %{
    name: "Afundo com Halteres",
    description: "Exercício unilateral para pernas",
    category: "strength",
    muscle_groups: ["quadriceps", "glutes"],
    equipment_needed: ["dumbbells"],
    difficulty_level: "intermediate",
    is_public: true
  },
  %{
    name: "Mesa Flexora",
    description: "Isolamento dos posteriores de coxa",
    category: "strength",
    muscle_groups: ["hamstrings"],
    equipment_needed: ["leg_curl_machine"],
    difficulty_level: "beginner",
    is_public: true
  },

  # Core
  %{
    name: "Prancha",
    description: "Fortalecimento do core",
    category: "strength",
    muscle_groups: ["core", "abs"],
    equipment_needed: [],
    difficulty_level: "beginner",
    is_public: true
  },
  %{
    name: "Abdominal Remador",
    description: "Exercício completo de abdômen",
    category: "strength",
    muscle_groups: ["abs", "core"],
    equipment_needed: [],
    difficulty_level: "intermediate",
    is_public: true
  },

  # Cardio
  %{
    name: "Corrida na Esteira",
    description: "Exercício cardiovascular básico",
    category: "cardio",
    muscle_groups: ["legs"],
    equipment_needed: ["treadmill"],
    difficulty_level: "beginner",
    is_public: true
  },
  %{
    name: "Bike Ergométrica",
    description: "Cardio de baixo impacto",
    category: "cardio",
    muscle_groups: ["legs"],
    equipment_needed: ["stationary_bike"],
    difficulty_level: "beginner",
    is_public: true
  },
  %{
    name: "Burpees",
    description: "Exercício de alta intensidade",
    category: "cardio",
    muscle_groups: ["full_body"],
    equipment_needed: [],
    difficulty_level: "advanced",
    is_public: true
  },

  # Flexibility
  %{
    name: "Alongamento de Posterior",
    description: "Alongamento da cadeia posterior",
    category: "flexibility",
    muscle_groups: ["hamstrings", "back"],
    equipment_needed: [],
    difficulty_level: "beginner",
    is_public: true
  }
]

Enum.each(exercises, fn exercise_data ->
  {:ok, exercise} = Workouts.create_exercise(Map.put(exercise_data, :trainer_id, trainer.id))
  IO.puts("Created exercise: #{exercise.name}")
end)

IO.puts("\n✅ Seed data created successfully!")
IO.puts("\nTrainer credentials:")
IO.puts("  Email: guilherme@gapersonal.com")
IO.puts("  Password: trainer123")
IO.puts("\nTest student credentials:")
IO.puts("  Email: maria.silva@example.com")
IO.puts("  Password: student123")
IO.puts("\n  Email: carlos.santos@example.com")
IO.puts("  Password: student123")
