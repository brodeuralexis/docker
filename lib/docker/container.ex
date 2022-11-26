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

  @derive {Inspect, only: [:attrs, :id, :image, :labels, :name, :short_id, :status]}
  @enforce_keys [:attrs, :id, :image, :labels, :name, :short_id, :status]
  defstruct [:attrs, :id, :image, :labels, :name, :short_id, :status]

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
  def prune(opts \\ []) do
    labels = accumulate(opts, :label)

    @adapter.prune_containers(%{
      label: labels
    })
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
