defmodule Docker.Network do
  @moduledoc """
  A representation of a Docker daemon network and a bunch of functions for
  dealing with networks.

  TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Network` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  For networks, the raw representation may change heavily depending of where the
  data came from.  The *List Networks* and *Inspect Netowkr* API return a
  different representation, the latter providing more information.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are available, and will ensure that the more detailed *Inspect Network*
  representation is user:
  ```elixir
  network = Docker.Network.reload!(network)
  ```
  """

  @typedoc """
  The ID of a [network](`Docker.Network`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of a Docker daemon [network](`Docker.Network`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          short_id: String.t(),
          name: String.t(),
          containers: Docker.NotLoaded | [String.t()]
        }

  @derive {Inspect, only: [:id, :short_id, :name]}
  @enforce_keys [:attrs, :id, :short_id, :name, :containers]
  defstruct [:attrs, :id, :short_id, :name, :containers]
end
