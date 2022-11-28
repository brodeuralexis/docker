defmodule Docker.Utilities do
  @moduledoc false

  @unix_units :second

  @doc """
  Converts the provided value to a UNIX timestamp.
  """
  @spec to_unix(term) :: pos_integer
  def to_unix(value)

  def to_unix(value) when is_integer(value) do
    value
  end

  def to_unix(value) when is_struct(value, NaiveDateTime) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(@unix_units)
  end

  def to_unix(value) when is_struct(value, DateTime) do
    value
    |> DateTime.to_unix(@unix_units)
  end

  def to_unix(value) when is_binary(value) do
    value
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(@unix_units)
  end

  def to_unix(other) do
    raise ArgumentError, "expected a timestamp, got: #{inspect(other)}"
  end

  @type spec_key :: atom | String.t()

  @type spec_value :: %{
          required(:to) => spec_key,
          optional(:repeatable) => true,
          optional(:transform) => (term -> term)
        }

  @type spec :: %{spec_key => spec_value}

  @doc """
  Cast the params using the given spec.
  """
  @spec cast(spec, map | list) :: map
  def cast(spec, params) do
    Enum.reduce(params, %{}, fn
      {key, value}, acc ->
        value_spec =
          case Access.fetch(spec, key) do
            {:ok, value_spec} ->
              value_spec

            :error ->
              raise ArgumentError, "unexpected :#{key} option"
          end

        transform = Access.get(value_spec, :transform, & &1)

        cond do
          value_spec[:repeatable] ->
            if is_list(value) do
              value = Enum.map(value, transform)
              Map.update(acc, value_spec[:to], value, &Kernel.++(value, &1))
            else
              value = transform.(value)
              Map.update(acc, value_spec[:to], [value], &List.insert_at(&1, 0, value))
            end

          not Map.has_key?(acc, value_spec[:to]) ->
            Map.put(acc, value_spec[:to], transform.(value))

          true ->
            raise ArgumentError, "unrepeatable :#{key} option repeated more then once"
        end
    end)
  end

  @doc """
  Transfers a value from one object to another.
  """
  @spec transfer(Enum.t(), term, Enum.t(), term) :: Enum.t()
  def transfer(dst, to, src, from) do
    case Access.fetch(src, from) do
      {:ok, value} ->
        put_in(dst, [to], value)

      :error ->
        dst
    end
  end
end
