defmodule Mix.Tasks.Phx.Gen.Typescript do
  @moduledoc """
  Generates TypeScript types from Ecto schemas.

  ## Usage

      mix phx.gen.typescript

  This will generate TypeScript interfaces in the frontend/shared/src/types/generated/ directory.
  """

  use Mix.Task

  @shortdoc "Generates TypeScript types from Ecto schemas"

  def run(_args) do
    Mix.Task.run("app.start")

    output_dir = Path.join([File.cwd!(), "frontend", "shared", "src", "types", "generated"])
    File.mkdir_p!(output_dir)

    schemas = [
      {GaPersonal.Accounts.User, "User"},
      {GaPersonal.Accounts.StudentProfile, "StudentProfile"},
      {GaPersonal.Schedule.TimeSlot, "TimeSlot"},
      {GaPersonal.Schedule.Appointment, "Appointment"},
      {GaPersonal.Workouts.Exercise, "Exercise"},
      {GaPersonal.Workouts.WorkoutPlan, "WorkoutPlan"},
      {GaPersonal.Workouts.WorkoutExercise, "WorkoutExercise"},
      {GaPersonal.Workouts.WorkoutLog, "WorkoutLog"},
      {GaPersonal.Evolution.BodyAssessment, "BodyAssessment"},
      {GaPersonal.Evolution.EvolutionPhoto, "EvolutionPhoto"},
      {GaPersonal.Evolution.Goal, "Goal"},
      {GaPersonal.Finance.Plan, "Plan"},
      {GaPersonal.Finance.Subscription, "Subscription"},
      {GaPersonal.Finance.Payment, "Payment"},
      {GaPersonal.Messaging.Message, "Message"},
      {GaPersonal.Messaging.Notification, "Notification"},
      {GaPersonal.Content.BlogPost, "BlogPost"},
      {GaPersonal.Content.Testimonial, "Testimonial"},
      {GaPersonal.Content.FAQ, "FAQ"}
    ]

    types_content = Enum.map_join(schemas, "\n\n", fn {module, name} ->
      generate_type(module, name)
    end)

    header = """
    // Auto-generated TypeScript types from Ecto schemas
    // Do not edit manually - run `mix phx.gen.typescript` to regenerate

    """

    File.write!(Path.join(output_dir, "index.ts"), header <> types_content)

    Mix.shell().info("✅ TypeScript types generated in #{output_dir}/index.ts")
  end

  defp generate_type(module, name) do
    fields = module.__schema__(:fields)

    type_fields =
      Enum.map_join(fields, "\n  ", fn field ->
        type = module.__schema__(:type, field)
        ts_type = ecto_to_ts_type(type)
        "#{field}: #{ts_type};"
      end)

    """
    export interface #{name} {
      #{type_fields}
    }
    """
  end

  defp ecto_to_ts_type(:id), do: "string"
  defp ecto_to_ts_type(:binary_id), do: "string"
  defp ecto_to_ts_type(:string), do: "string"
  defp ecto_to_ts_type(:integer), do: "number"
  defp ecto_to_ts_type(:float), do: "number"
  defp ecto_to_ts_type(:decimal), do: "number"
  defp ecto_to_ts_type(:boolean), do: "boolean"
  defp ecto_to_ts_type(:date), do: "string"
  defp ecto_to_ts_type(:time), do: "string"
  defp ecto_to_ts_type(:utc_datetime), do: "string"
  defp ecto_to_ts_type(:naive_datetime), do: "string"
  defp ecto_to_ts_type(:map), do: "Record<string, any>"
  defp ecto_to_ts_type({:array, :string}), do: "string[]"
  defp ecto_to_ts_type({:array, :integer}), do: "number[]"
  defp ecto_to_ts_type({:array, _}), do: "any[]"
  defp ecto_to_ts_type(_), do: "any"
end
