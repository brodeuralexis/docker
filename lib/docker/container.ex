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
end
