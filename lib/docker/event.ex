defmodule Docker.Event do
  @moduledoc """
  The representation of a Docker daemon event and a bunch of functions for
  dealing with events.

  # TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Event` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.


  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.
  """

  @adapter Application.compile_env(:docker, :adapter, Docker.DefaultAdapter)

  alias Docker.Exception

  @typedoc """
  Representation of a Docker daemon [event](`Docker.Event`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          resource: String.t(),
          id: String.t(),
          event: String.t()
        }

  @derive {Inspect, only: [:resource, :id, :event]}
  @enforce_keys [:attrs, :resource, :id, :event]
  defstruct [:attrs, :resource, :id, :event]

  def stream(opts \\ []) do
    {heir, opts} = Keyword.pop(opts, :heir, nil)
    {since, opts} = Keyword.pop(opts, :since, 0)
    {until, opts} = Keyword.pop(opts, :until, nil)

    opts =
      opts
      |> prepare_list_opts()
      |> Map.put(:since, Docker.Utilities.Transform.unix(since))

    opts =
      case heir do
        nil ->
          opts

        heir when not is_nil(heir) ->
          Map.put(opts, :heir, heir)
      end

    opts =
      case until do
        nil ->
          opts

        until when not is_nil(until) ->
          Map.put(opts, :until, Docker.Utilities.Transform.unix(until))
      end

    @adapter.stream_events(opts)
  end

  @typedoc """
  The options that may be provided to the `list/1` function.
  """
  @type list_opts ::
          Enumerable.t(
            {:resource, atom | String.t() | [atom | String.t()]}
            | {:type, atom | String.t() | [atom | String.t()]}
            | {:since, pos_integer | NaiveDateTime.t() | DateTime.t()}
            | {:until, pos_integer | NaiveDateTime.t() | DateTime.t()}
          )

  @doc """
  Lists [events](`Docker.Event`).

  If the `:until` option is provided with a date and time in the future, the
  call to this function will block until such a time.

  ## Non-Repeatable Options

    - `:since` takes a `NaiveDateTime` compatible string or data structure and
      returns every events after that moment.  Defaults to the beginning of
      time.
    - `:until` takes a `NaiveDateTime` compatible string or data structure and
      return every events before that moment.  Defaults to now.

  ## Filtering Options

  All filtering options are repeatable, and allow one to build a whitelist of
  all requested [events](`Docker.Event`).  They are repeatable either by
  providing an array of values, and/or by repeating the same option multiple
  times in a keyword list.

    - `:resource` takes the type of the resource.
    - `:type` takes the type of events.
  """
  @spec list() :: {:ok, [t]} | {:error, Exception.t()}
  @spec list(list_opts) :: {:ok, [t]} | {:error, Exception.t()}
  def list(opts \\ []) do
    {since, opts} = Keyword.pop(opts, :since, 0)

    {until, opts} =
      Keyword.pop(
        opts,
        :until,
        DateTime.utc_now() |> DateTime.to_unix(:second) |> to_string()
      )

    opts =
      opts
      |> prepare_list_opts()
      |> Map.put(:since, Docker.Utilities.Transform.unix(since))
      |> Map.put(:until, until)

    @adapter.list_events(opts)
  end

  @doc """
  Lists [events](`Docker.Event`).

  Unlike `list/1`, this function will *raise* if an error occurs, or retunr the
  events directly on success.

  For more information about usage and options, see `list/1`.
  """
  @spec list!() :: [t]
  @spec list!(list_opts) :: [t]
  def list!(opts \\ []) do
    case list(opts) do
      {:ok, events} ->
        events

      {:error, reason} ->
        raise reason
    end
  end

  defp prepare_list_opts(opts) do
    Enum.reduce(opts, %{}, fn
      {key, _value}, _acc when key in [:since, :until] ->
        raise ArgumentError, "unrepeatable :#{key} option must not be repeated"

      {key, value}, acc when (key in [:resource, :type] and is_binary(value)) or is_atom(value) ->
        Map.update(acc, key, [value], &List.insert_at(&1, 0, value))

      {key, values}, acc when key in [:resource, :type] and is_list(values) ->
        Map.update(acc, key, values, &Kernel.++(&1, values))

      {key, other}, _acc when key in [:resource, :type] ->
        raise ArgumentError,
              "expected :#{key} option to be a string, an atom, or a list, got: #{inspect(other)}"

      {key, _other}, _acc ->
        raise ArgumentError, "unexpected :#{key} option"
    end)
  end
end
