defmodule Docker.Plugin do
  @moduledoc """
  The representation of a Docker daemon plugin and a bunch of functions for
  dealing with plugins.

  # TODO: More information

  ## Raw Representation

  Not all fields returned by the DOcker daemon are provided on the
  `Docker.Plugin` data structure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are available:
  ```elixir
  plugin = Docker.Plugin.reload!(plugin)
  ```
  """

  @typedoc """
  The ID of a [plugin](`Docker.Plugin`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of a Docker daemon [plugin](`Docker.Plugin`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          short_id: String.t(),
          name: String.t(),
          enabled: boolean,
          settings: any
        }

  @derive {Inspect, only: [:id, :short_id, :name, :enabled, :settings]}
  @enforce_keys [:attrs, :id, :short_id, :name, :enabled, :settings]
  defstruct [:attrs, :id, :short_id, :name, :enabled, :settings]
end
