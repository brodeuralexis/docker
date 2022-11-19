defmodule Docker.Node do
  @moduledoc """
  The representation of a Docker daemon node and a bunch of functions for
  dealing with nodes.

  TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the `Docker.Node`
  data structure.  Only a subset of fields are supported to ensure compatibility
  between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are available:
  ```elixir
  node = Docker.Node.reload!(node)
  ```
  """

  @typedoc """
  The ID of a Docker daemon [node](`Docker.Node`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of Docker daemon [node](`Docker.Node`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          short_id: String.t(),
          version: integer
        }

  @derive {Inspect, only: [:id, :short_id, :version]}
  @enforce_keys [:attrs, :id, :short_id, :version]
  defstruct [:attrs, :id, :short_id, :version]
end
