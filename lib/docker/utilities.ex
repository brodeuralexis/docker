defmodule Docker.Utilities do
  @moduledoc false

  @type accumulate_opts ::
          Enumerable.t(
            {:unrepeatable, [term]}
            | {:repeatable, [term]}
          )

  @spec accumulate(Enumerable.t({term, term}), term, accumulate_opts) :: [term]
  def accumulate(params, key, opts \\ []) do
    unrepeatable = Keyword.get(opts, :unrepeatable, [])
    repeatable = Keyword.get(opts, :repeatable, [])

    Enum.reduce(params, %{}, fn
      {^key, value}, acc when not is_list(value) ->
        List.insert_at(acc, 0, value)

      {^key, values}, acc when is_list(values) ->
        values ++ acc

      {key, _other}, acc ->
        cond do
          key in unrepeatable ->
            raise ArgumentError, "unrepeatable :#{key} option must not be repeated"

          key in repeatable ->
            acc

          true ->
            raise ArgumentError, "unexpected :#{key} option"
        end
    end)
  end

  defmacro transfer(dst, to, src, from, do: body) do
    quote do
      case Access.fetch(unquote(src), unquote(from)) do
        {:ok, var!(value)} ->
          put_in(unquote(dst), [unquote(to)], unquote(body))

        :error ->
          unquote(dst)
      end
    end
  end

  defmacro transfer(dst, to, src, from) do
    quote do
      case Access.fetch(unquote(src), unquote(from)) do
        {:ok, value} ->
          put_in(unquote(dst), [unquote(to)], value)

        :error ->
          unquote(dst)
      end
    end
  end
end
