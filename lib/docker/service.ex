defmodule Docker.Service do
  @moduledoc """
  A representation of a Docker daemon service and a bunch of functions for
  dealing with services.

  TODO: More information

  ## Versionning

  TODO: Describe Versionning

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Service` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  To refresh the raw represetnation, the `reload/1` and `reload!/1` functions
  are available:
  ```elixir
  service = Docker.Service.reload!(service)
  ```
  """

  @typedoc """
  The ID of a [service](`Docker.Service`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of a Docker daemon [service](`Docker.Service`).
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
end
