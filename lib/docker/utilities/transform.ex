defmodule Docker.Utilities.Transform do
  @moduledoc false

  def unix(value) when is_integer(value) do
    value
  end

  def unix(%NaiveDateTime{} = value) do
    DateTime.from_naive!(value, "Etc/UTC")
  end

  def unix(%DateTime{} = value) do
    DateTime.to_unix(value, :second)
  end

  def unix(value) do
    raise ArgumentError, "value cannot be converted to a unix timestamp: #{inspect(value)}"
  end
end
