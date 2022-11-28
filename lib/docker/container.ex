defmodule Docker.Container do
  @moduledoc """
  A representation of a Docker daemon container and a bunch of functions for
  dealing with containers.

  TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Container` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  For containers, the raw representation may change heavily depending of where
  the data came from.  The *List Containers* and *Inspect Container*  API return
  a different raw representation, the latter providing more information.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are available, and will ensure that the more detailed *Inspect Container*
  representation is used:
  ```elixir
  container = Docker.Container.reload!(container)
  ```
  """

  require Docker.Utilities
  import Docker.Utilities

  @adapter Application.compile_env(:docker, :adapter, Docker.DefaultAdapter)

  @typedoc """
  The ID of a [container](`Docker.Container`).
  """
  @type id :: String.t()

  @typedoc """
  The status of a [container](`Docker.Container`).
  """
  @type status :: :created | :restarting | :running | :removing | :paused | :exited | :dead

  @typedoc """
  The health of a [container](`Docker.Container`).
  """
  @type health :: :starting | :healthy | :unhealthy | :none

  @typedoc """
  Representation of a Docker daemon [container](`Docker.Container`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          image: String.t(),
          labels: %{String.t() => String.t()},
          name: String.t(),
          short_id: String.t(),
          status: status
        }

  @derive {Inspect, only: [:id, :image, :labels, :name, :short_id, :status]}
  @enforce_keys [:attrs, :id, :image, :labels, :name, :short_id, :status]
  defstruct [:attrs, :id, :image, :labels, :name, :short_id, :status]

  @typedoc """
  The options that may be provided to the `list/1` function.
  """
  @type list_opts :: Enumerable.t()

  @doc """
  Lists [containers](`Docker.Container`).

  ## TODO: Options
  """
  @spec list() :: {:ok, [t]} | {:error, Exception.t()}
  @spec list(list_opts) :: {:ok, [t]} | {:error, Exception.t()}
  def list(_opts \\ []) do
    @adapter.list_containers(%{})
  end

  @doc """
  Lists [containers](`Docker.Container`).

  Unlike `list/1`, this function will *raise* if an error occurs, or return the
  list directly on success.

  For more information about usage and options, see `list/1`.
  """
  @spec list!() :: [t]
  @spec list!(list_opts) :: [t]
  def list!(opts \\ []) do
    case list(opts) do
      {:ok, containers} ->
        containers

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Gets a [container](`Docker.Container`).
  """
  @spec get(String.t()) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def get(id_or_name) when is_binary(id_or_name) do
    @adapter.inspect_container(id_or_name)
  end

  @doc """
  Gets a [container](`Docker.Container`).

  Unlike `get/1`, this function will *raise* if an error occurs, or return the
  container directly on success.

  For more information about usage, see `get/1`.
  """
  @spec get!(String.t()) :: t
  def get!(id_or_name) do
    case get(id_or_name) do
      {:ok, container} ->
        container

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Reloads a [container](`Docker.Container`).
  """
  @spec reload(t) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def reload(%__MODULE__{id: id}) do
    get(id)
  end

  @doc """
  Reloads a [container](`Docker.Container`).

  Unlike `reload/1`, this function will *raise* if an error occurs, or return
  the container directly on success.

  For more information about usage, see `reload/1`.
  """
  @spec reload!(t) :: t
  def reload!(%__MODULE__{id: id}) do
    get!(id)
  end

  @typedoc """
  The options that may be provided to the `prune/1` function.
  """
  @type prune_opts :: Enumerable.t({:label, String.t() | [String.t()]})

  @doc """
  Removes all stopped containers.

  ## Repeatable Options

  They are repeatable either by providing an array of values, and/or by
  repeating the same option multiple times in the keyword list.

    - `:label` takes a [container](`Docker.Container`) label in the form of
      `key` or `key=value`.
  """
  @spec prune() :: {:ok, [id]} | {:error, Exception.t()}
  @spec prune(prune_opts) :: {:ok, [id]} | {:error, Exception.t()}
  def prune(_opts \\ []) do
    # labels = accumulate(opts, :label)

    @adapter.prune_containers(%{})
  end

  @doc """
  Removes all stopped containers.

  Unlike `prune/1`, this function will *raise* if an error occurs, or return the
  result directly on success.

  For more information about usage and options, see `prune/1`.
  """
  @spec prune!() :: [id]
  @spec prune!(prune_opts) :: [id]
  def prune!(opts \\ []) do
    case prune(opts) do
      {:ok, container_ids} ->
        container_ids

      {:error, reason} ->
        raise reason
    end
  end
end
