defmodule Docker.Config do
  @moduledoc """
  Thef representation of a Docker daemon config and a bunch of functions for
  dealing with configs.

  # TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Config` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  To refresh the raw representation, the `reload/1` and `reload/1` functions
  are available:
  ```elixir
  config = Docker.Config.reload!(config)
  ```
  """

  @adapter Application.compile_env(:docker, :adapter, Docker.Adapters.DefaultAdapter)

  alias Docker.Exception
  alias Docker.NotFound

  @typedoc """
  The ID of a Docker daemon [config](`Docker.Config`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of a Docker daemon [config](`Docker.Config`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          name: String.t()
        }

  @derive {Inspect, only: [:id, :name]}
  @enforce_keys [:attrs, :id, :name]
  defstruct [:attrs, :id, :name]

  @typedoc """
  The list of options that may be provided to the `list/1` function.
  """
  @type list_opts ::
          Enumerable.t(
            {:id, String.t() | [String.t()]}
            | {:label, String.t() | [String.t()]}
            | {:name, String.t() | [String.t()]}
          )

  @doc """
  Lists [configs](`Docker.Config`).

  ## Filtering Options

  All filtering options are repeatable, and allow one to build a whitelist of
  all requested [configs](`Docker.Config`).  They are repeatable either by
  providing an array of values, and/or by repeating the same option multiple
  times in the keyword list.

    - `:id` takes a [config](`Docker.Config`) ID.
    - `:label` takes a [config](`Docker.Config`) label in the form of `key` or
      `key=value`.
    - `:name` takes a [config](`Docker.Config`) name.
  """
  @spec list() :: {:ok, [t]} | {:error, Exception.t()}
  @spec list(list_opts) :: {:ok, [t]} | {:error, Exception.t()}
  def list(opts \\ []) do
    opts = prepare_list_opts(opts)

    @adapter.list_configs(opts)
  end

  @doc """
  Lists [configs](`Docker.Config`).

  Unlike `list/1`, this function will *raise* if an error occurs, or return the
  list directly on success.

  For more information about usage and options, see `list/1`.
  """
  @spec list!() :: [t]
  @spec list!(list_opts) :: [t]
  def list!(opts \\ []) do
    case list(opts) do
      {:ok, configs} ->
        configs

      {:error, reason} ->
        raise reason
    end
  end

  defp prepare_list_opts(opts) do
    Enum.reduce(opts, %{}, fn
      {key, value}, acc when key in [:id, :label, :name] and is_binary(value) ->
        Map.update(acc, key, [value], &List.insert_at(&1, 0, value))

      {key, values}, acc when key in [:id, :label, :name] and is_list(values) ->
        Map.update(acc, key, values, &Kernel.++(&1, values))

      {key, other}, _acc when key in [:id, :label, :name] ->
        raise ArgumentError,
              "expected :#{key} option to be a string or a list, got: #{inspect(other)}"

      {key, _other}, _acc ->
        raise ArgumentError,
              "unexpected :#{key} option"
    end)
  end

  @doc """
  Gets a [config](`Docker.Config`).
  """
  @spec get(String.t()) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def get(id) when is_binary(id) do
    @adapter.inspect_config(id)
  end

  @doc """
  Gets a [config](`Docker.Config`).

  Unlike `get/1`, this function will *raise* if an error occurs, or return the
  config directly on success.

  For more information about usage, see `get/1`.
  """
  @spec get!(String.t()) :: t
  def get!(id) when is_binary(id) do
    case get(id) do
      {:ok, config} ->
        config

      {:error, reason} ->
        raise reason
    end
  end

  @typedoc """
  The list of options that may be provided to the `create/1` function.
  """
  @type create_opts ::
          Enumerable.t(
            {:label, {String.t(), String.t()} | Enumerable.t({String.t(), String.t()})}
            | {:templating, map}
          )

  @doc """
  Creates a [config](`Docker.Config`).

  ## Options

    - `:label` takes a 2 element tuple as a key-value pair for a label.  This
      option can be repeated multiple times, and will accumulate labels.  Labels
      provided later will override earlier labels.
    - `:templating` takes a templating driver configuration.
  """
  @spec create(String.t(), binary) :: {:ok, t} | {:error, Exception.t()}
  @spec create(String.t(), binary, create_opts) :: {:ok, t} | {:error, Exception.t()}
  def create(name, data, opts \\ []) when is_binary(name) and is_binary(data) do
    {templating, opts} = Keyword.pop(opts, :templating)
    labels = prepare_create_labels(opts)

    with {:ok, id} = @adapter.create_config(name, data, labels, templating),
         {:ok, config} = @adapter.inspect_config(id) do
      {:ok, config}
    end
  end

  @doc """
  Creates a [config](`Docker.Config`).

  Unlike `create/3`, this function will *raise* if an error occurs, or return
  the config directly on success.

  For more information about usage and options, see `create/1`.
  """
  @spec create!(String.t(), binary) :: t
  @spec create!(String.t(), binary, create_opts) :: t
  def create!(name, data, opts \\ []) when is_binary(name) and is_binary(data) do
    case create(name, data, opts) do
      {:ok, config} ->
        config

      {:error, reason} ->
        raise reason
    end
  end

  defp prepare_create_labels(opts) do
    Enum.reduce(opts, %{}, fn
      {:label, {key, value}}, acc ->
        Map.put(acc, key, value)

      {:label, labels}, acc when is_list(labels) ->
        Map.merge(acc, Map.new(labels))

      {:label, labels}, acc when is_map(labels) ->
        Map.merge(acc, labels)

      {:labels, other}, _acc ->
        raise ArgumentError,
              "expected :label option to be a tuple, a list of tuples, or a map, got: #{inspect(other)}"

      {key, _other}, _acc ->
        raise ArgumentError, "unexpected :#{key} option"
    end)
  end

  @doc """
  Removes a [config](`Docker.Config`).
  """
  @spec remove(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove(id) when is_binary(id) do
    @adapter.remove_config(id)
  end

  @spec remove(t) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove(%__MODULE__{id: id}) do
    remove(id)
  end

  @doc """
  Removes a [config](`Docker.Config`).

  Unlike `remove/1`, this function will *raise* if an error occurs, or return
  nothing on success.

  For more information about usage, see `remove/1`.
  """
  @spec remove!(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}
  @spec remove!(t) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove!(id_or_config) do
    case remove(id_or_config) do
      :ok ->
        :ok

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Reloads a [config](`Docker.Config`).
  """
  @spec reload(t) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def reload(%__MODULE__{id: id}) do
    get(id)
  end

  @doc """
  Reloads a [config](`Docker.Config`).

  Unlike `reload/1`, this function will *raise* if an error occurs, or return
  the config directly on success.

  For more information about usage, see `reload/1`.
  """
  @spec reload!(t) :: t
  def reload!(%__MODULE__{id: id}) do
    get!(id)
  end
end
