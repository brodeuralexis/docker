defmodule Docker.Volume do
  @moduledoc """
  A representation of a Docker daemon volume and a bunch of functions for
  dealing with volumes.

  TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Volume` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are available:
  ```elixir
  volume = Docker.Volume.reload!(volume)
  ```
  """

  @adapter Application.compile_env(:docker, :adapter, Docker.DefaultAdapter)

  @typedoc """
  Representation of a Docker daemon [volume](`Docker.Volume`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          name: String.t()
        }

  @derive {Inspect, only: [:name]}
  @enforce_keys [:attrs, :name]
  defstruct [:attrs, :name]

  @typedoc """
  The list of options that may be provided to the `list/1` function.
  """
  @type list_opts ::
          [
            {:driver, String.t() | [String.t()]}
            | {:label, String.t() | [String.t()]}
            | {:name, String.t() | [String.t()]}
          ]

  @doc """
  Lists [volumes](`Docker.Volume`).

  ## Filtering Options

  The following options may only occur once at most.

    - `:dangling` (`t:boolean`) indicates if all volumes (true) must be returned, or
      only volumes already in use by containers (false).

  The following filtering options are repeatable, and allow one to build a
  whitelist of all requested [volumes](`Docker.Volume`).  They are repeatable
  either by providing an array of values, and/or by repeating the same option
  multiple times in the keyword list.

    - `:driver` takes a [volume](`Docker.Volume`) driver.
    - `:label` takes a [volume](`Docker.Volume`) label in the form of `key` or
      `key=value`.
    - `:name` takes a [volume](`Docker.Volume`) name.
  """
  @spec list() :: {:ok, [Volume.t()]} | {:error, Exception.t()}
  @spec list(list_opts) :: {:ok, [Volume.t()]} | {:error, Exception.t()}
  def list(opts \\ []) do
    {dangling, opts} = Keyword.pop(opts, :dangling, true)
    opts = prepare_list_opts(opts)
    opts = Map.put(opts, :dangling, [to_string(dangling)])

    @adapter.list_volumes(opts)
  end

  @doc """
  Lists [volumes](`Docker.Volume`).

  Unlike `list/1`, this function will *raise* if an error occurs, or return the
  list directly on success.

  For more information about usage and options, see `list/1`.
  """
  @spec list!() :: [Volume.t()]
  @spec list!(list_opts) :: [Volume.t()]
  def list!(opts \\ []) do
    case list(opts) do
      {:ok, volumes} ->
        volumes

      {:error, reason} ->
        raise reason
    end
  end

  defp prepare_list_opts(opts) do
    Enum.reduce(opts, %{}, fn
      {:dangling, _value}, _acc ->
        raise ArgumentError,
              "unrepeatable :dangling option must not be repeated"

      {key, value}, acc when key in [:driver, :label, :name] and is_binary(value) ->
        Map.update(acc, key, [value], &List.insert_at(&1, 0, value))

      {key, values}, acc when key in [:driver, :label, :name] and is_list(values) ->
        Map.update(acc, key, values, &Kernel.++(&1, values))

      {key, other}, _acc when key in [:driver, :label, :name] ->
        raise ArgumentError,
              "expected :#{key} option to be a string or a list, got: #{inspect(other)}"

      {key, _other}, _acc ->
        raise ArgumentError,
              "unexpected :#{key} option"
    end)
  end

  @doc """
  Gets a [volume](`Docker.Volume`).
  """
  @spec get(String.t()) :: {:ok, t()} | {:error, Exception.t() | NotFound.t()}
  def get(name) when is_binary(name) do
    @adapter.inspect_volume(name)
  end

  @doc """
  Gets a [volume](`Docker.Volume`).

  Unline `get/1`m this function will *raise* if an error occurs, or return the
  volume directly on success.

  For more information about usage, see `get/1`.
  """
  def get!(name) when is_binary(name) do
    case get(name) do
      {:ok, volume} ->
        volume

      {:error, reason} ->
        raise reason
    end
  end

  @typedoc """
  The list of options that may be provided to the `create/1` function.
  """
  @type create_opts ::
          [
            {:driver, String.t()}
            | {:driver_opts, map}
            | {:label, {String.t(), String, t} | Enumerable.t({String.t(), String.t()})}
          ]

  @doc """
  Creates a [volume](`Docker.Volume`).

  ## Options

    - `:driver` takes a string representing the driver to use for the volume.
    - `:driver_opts` takes a map of options for the driver.
    - `:label` takes a 2 element  tuple as a key-value pair for a label.  This
      option can be repeated multiple times, and will accumulate labels.  Labels
      provided later will override earlier labels.
  """
  @spec create(String.t()) :: {:ok, t} | {:error, Exception.t()}
  @spec create(String.t(), create_opts) :: {:ok, t} | {:error, Exception.t()}
  def create(name, opts \\ []) do
    {driver, opts} = Keyword.pop(opts, :driver, "local")
    {driver_opts, opts} = Keyword.pop(opts, :driver_opts, %{})
    labels = prepare_create_labels(opts)

    opts = %{
      driver: driver,
      driver_opts: Map.new(driver_opts),
      labels: labels
    }

    with {:ok, id} <- @adapter.create_volume(name, opts),
         {:ok, volume} <- @adapter.inspect_volume(id) do
      {:ok, volume}
    end
  end

  @doc """
  Creates a [volume](`Docker.Volume`).

  Unline `create!/2`, this function will *raise* if an error occurs, or return
  the volume directly on success.

  For more information about usage and options, see `create/3`.
  """
  @spec create!(String.t()) :: t
  @spec create!(String.t(), create_opts) :: t
  def create!(name, opts \\ []) do
    case create(name, opts) do
      {:ok, volume} ->
        volume

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
  Removes a [volume](`Docker.Volume`).
  """
  @spec remove(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove(id) when is_binary(id) do
    @adapter.remove_volume(id)
  end

  @spec remove(t) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove(%__MODULE__{name: name}) do
    @adapter.remove_volume(name)
  end

  @doc """
  Removes a [volume](`Docker.Volume`).

  Unline `remove/1`, this function will *raise* if an error occurs, or return
  on success.

  For more information about usage, see `remove/1`.
  """
  @spec remove!(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}
  @spec remove!(t) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove!(id_or_volume) do
    case remove(id_or_volume) do
      :ok ->
        :ok

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Reloads a [volume](`Docker.Volume`).
  """
  @spec reload(t) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def reload(%__MODULE__{name: name}) do
    get(name)
  end

  @doc """
  Reloads a [volume](`Docker.Volume`).

  Unlike `reload/1`, this function will *raise* if an error occurs, or return
  the volume directly on success.

  For more information abou usage, see `reload/1`.
  """
  @spec reload!(t) :: t
  def reload!(%__MODULE__{name: name}) do
    get!(name)
  end
end
