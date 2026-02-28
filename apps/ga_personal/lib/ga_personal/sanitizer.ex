defmodule GaPersonal.Sanitizer do
  @moduledoc """
  Input sanitization for text fields.
  Strips HTML tags and normalizes whitespace to prevent stored XSS.
  """

  @html_tag_regex ~r/<[^>]*>/
  @multiple_spaces_regex ~r/\s{2,}/

  @doc """
  Strips HTML tags from a string and normalizes whitespace.
  Returns nil for nil input.
  """
  def sanitize(nil), do: nil

  def sanitize(value) when is_binary(value) do
    value
    |> String.replace(@html_tag_regex, "")
    |> String.replace(@multiple_spaces_regex, " ")
    |> String.trim()
  end

  def sanitize(value), do: value

  @doc """
  Sanitizes a list of strings (e.g., tags, muscle_groups).
  """
  def sanitize_list(nil), do: nil

  def sanitize_list(list) when is_list(list) do
    Enum.map(list, &sanitize/1)
  end

  def sanitize_list(value), do: value

  @doc """
  Sanitizes specified string fields in a changeset.
  """
  def sanitize_changeset(changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, fn field, cs ->
      case Ecto.Changeset.get_change(cs, field) do
        nil -> cs
        value when is_binary(value) -> Ecto.Changeset.put_change(cs, field, sanitize(value))
        value when is_list(value) -> Ecto.Changeset.put_change(cs, field, sanitize_list(value))
        _ -> cs
      end
    end)
  end
end
