defmodule Docker.Secret do
  @moduledoc """
  A representation of a Docker daemon secret and a bunch of functions for
  dealing with secrets.

  # TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Secret` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are available:
  ```elixir
  secret = Docker.Secret.reload!(secret)
  ```
  """

  alias Docker.{Exception, NotFound}

  @adapter Application.compile_env(:docker, :adapter, Docker.DefaultAdapter)

  @typedoc """
  The ID of a [secret](`Docker.Secret`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of a Docker daemon [secret](`Docker.Secret`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          short_id: String.t(),
          name: String.t(),
          version: integer
        }

  @derive {Inspect, only: [:id, :short_id, :name, :version]}
  @enforce_keys [:attrs, :id, :short_id, :name, :version]
  defstruct [:attrs, :id, :short_id, :name, :version]

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
  Lists [secrets](`Docker.Secret`).

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

    @adapter.list_secrets(opts)
  end

  @doc """
  Lists [secrets](`Docker.Secret`).

  Unlike `list/1`, this function will *raise* if an error occurs, or return the
  list directly on success.

  For more information about usage and options, see `list/1`.
  """
  @spec list!() :: [t]
  @spec list!(list_opts) :: [t]
  def list!(opts \\ []) do
    case list(opts) do
      {:ok, secrets} ->
        secrets

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
  Gets a [secret](`Docker.Secret`).
  """
  @spec get(String.t()) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def get(id) do
    @adapter.inspect_secret(id)
  end

  @doc """
  Gets a [secret](`Docker.Secret`).

  Unlike `get/1`, this function will *raise* if an error occurs, or return the
  secret directly on success.

  For more information about usage, see `get/1`.
  """
  @spec get!(String.t()) :: t
  def get!(id) do
    case get(id) do
      {:ok, secret} ->
        secret

      {:error, reason} ->
        raise reason
    end
  end

  @typedoc """
  The list of options that may be provided to the `create/3` function.
  """
  @type create_opts ::
          Enumerable.t(
            {:label, {String.t(), String.t()} | Enumerable.t({String.t(), String.t()})},
            {:driver, String.t()},
            {:driver_opts, map}
          )

  @doc """
  Creates a [secret](`Docker.Secret`).

  ## Options

    - `:label` takes a 2 element tuple as a key-value pair for a label.  This
      option can be repeated multiple times, and will accumulate labels.  Labels
      provided later will override earlier labels.
    - `:driver` takes a driver name.
    - `:driver_opts` takes a driver options map.
  """
  @spec create(String.t(), binary) :: {:ok, t} | {:error, Exception.t()}
  @spec create(String.t(), binary, create_opts) :: {:ok, t} | {:error, Exception.t()}
  def create(name, value, opts \\ []) do
    {driver, opts} = Keyword.pop(opts, :driver, nil)
    {driver_opts, opts} = Keyword.pop(opts, :driver_opts, %{})
    labels = prepare_create_labels(opts)

    opts = %{labels: labels}

    opts =
      if driver do
        Map.merge(opts, %{
          driver: driver,
          driver_opts: Map.new(driver_opts)
        })
      else
        opts
      end

    with {:ok, id} <- @adapter.create_secret(name, value, opts),
         {:ok, secret} <- @adapter.inspect_secret(id) do
      {:ok, secret}
    end
  end

  @doc """
  Creates a [secret](`Docker.Secret).

  Unlike `secret/3`, this function will *raise* if an error occurs, or return
  the secret directly on success.

  For more information about usage and options, see `create/3`.
  """
  @spec create!(String.t(), binary) :: t
  @spec create!(String.t(), binary, create_opts) :: t
  def create!(name, value, opts \\ []) do
    case create(name, value, opts) do
      {:ok, secret} ->
        secret

      {:error, reason} ->
        raise reason
    end
  end

  defp prepare_create_labels(opts) do
    Enum.reduce(opts, %{}, fn
      {key, _other}, _acc when key in [:driver, :driver_opts] ->
        raise ArgumentError,
              "unrepeatable :#{key} option must not be repeated"

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
        raise ArgumentError,
              "unexpected :#{key} option"
    end)
  end

  @type update_opts ::
          Enumerable.t(
            {:label, {String.t(), String.t()} | Enumerable.t({String.t(), String.t()})}
          )

  @doc """
  Updates a [secret](`Docker.Secret`).

  ## Options

    - `:label` takes a 2 element tuple as a key-value pair for a label.  This
      option can be repeated multiple times, and will accumulate labels.  Labels
      provided later will override earlier labels.
  """
  @spec update(t) :: {:ok, t}
  @spec update(t, update_opts) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def update(%__MODULE__{} = secret, opts \\ []) do
    labels = prepare_update_labels(opts)

    opts = %{labels: labels}

    with {:ok, id} <- @adapter.update_secret(secret, opts),
         {:ok, secret} <- @adapter.inspect_secret(id) do
      {:ok, secret}
    end
  end

  @doc """
  Updates a [secret](`Docker.Secret`).

  Unlike `update/2`, this function will *raise* if an error occurs, or return
  nothing on success.

  For more information about usage, see `update/2`.
  """
  @spec update!(t) :: t
  @spec update!(t, update_opts) :: t
  def update!(%__MODULE__{} = secret, opts \\ []) do
    case update(secret, opts) do
      {:ok, secret} ->
        secret

      {:error, reason} ->
        raise reason
    end
  end

  defp prepare_update_labels(opts) do
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
        raise ArgumentError,
              "unexpected :#{key} option"
    end)
  end

  @doc """
  Removes a [secret](`Docker.Secret`).
  """
  @spec remove(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove(id) when is_binary(id) do
    @adapter.remove_secret(id)
  end

  @spec remove(t) :: :ok | {:error, Exception.t() | NotFound.t()}
  def remove(%__MODULE__{id: id}) do
    @adapter.remove_secret(id)
  end

  @doc """
  Removes a [secret](`Docker.Secret`).

  Unlike `remove/1`, this function will *raise* if an error occurs, or return
  directly on success.

  For more information about usage, see `remove/1`.
  """
  @spec remove!(t | String.t()) :: :ok
  def remove!(id_or_secret) do
    case remove(id_or_secret) do
      :ok ->
        :ok

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Reloads a [secret](`Docker.Secret`).
  """
  @spec reload(t) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def reload(%__MODULE__{id: id}) do
    get(id)
  end

  @doc """
  Reloads a [secret](`Docker.Secret`).

  Unlike `reload/1`, this function will *raise* if an error occurs, or return
  the secret directly on success.

  For more information about usage, see `reload/1`.
  """
  @spec reload!(t) :: t
  def reload!(%__MODULE__{id: id}) do
    get!(id)
  end
end
